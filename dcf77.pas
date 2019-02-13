{
 /***************************************************************************
                                   dcf77.pas
                                   ---------


 ***************************************************************************/

 *****************************************************************************
  This file is part of the Lazarus packages by Andreas Jakobsche

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit DCF77;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, GPIO,
  ExtCtrls;

type

  TClockState = (
    csSyncSecStart  {möglichen Anfang einer Sekunde suchen},
    csCheckSecStart {Prüfung, ob tatsächlich ein Sekundenstart gefunden wurde},
    csSyncMin       {Minutenanfang suchen});

  TTimeRec = record
    Sec, Min, Hour: Byte;
    Change_CET_CEST: Boolean; {Zeitumstellung am Ende der Stunde}
    CEST: Boolean; {Sommerzeit}
    LeapSec: Boolean; {Am Ende der Stunde wird eine Schaltsekunde eingefügt}
  end;

type

  { TDCF77Clock }

  TDCF77Clock = class(TComponent)
  private
    FGPIO: TGPIOPort;
    FTimer: TTimer;
    function GetInput: TGPIOPort;
    function GetTimer: TTimer;
  private
    FBit, Check0, Check1: Boolean;
    ClockState: TClockState;
    FSecond: Byte;
    Prepare, Current: TTimeRec;
    Pulse: Byte;
    procedure CountPulse;
    function GetActiveLow: Boolean;
    function GetInputAddr: TGPIOAddress;
    procedure CheckInput(Sender: TObject);
    procedure SetActiveLow(const AValue: Boolean);
    procedure SetInputAddr(const AValue: TGPIOAddress);
    { Private declarations }
    property Input: TGPIOPort read GetInput;
    property Timer: TTimer read GetTimer;
  protected
    { Protected declarations }
  public
    { Public declarations }
    property Bit: Boolean read FBit;
    property Second: Byte read FSecond;
  published
    { Published declarations }
    property ActiveLow: Boolean read GetActiveLow write SetActiveLow;
    property InputAddr: TGPIOAddress read GetInputAddr write SetInputAddr;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Hardware',[TDCF77Clock]);
end;

{ TDCF77Clock }

function TDCF77Clock.GetInput: TGPIOPort;
begin
  if not Assigned(FGPIO) then begin
    FGPIO := TGPIOPort.Create(Self);
    FGPIO.Direction := pdInput;
  end;
  Result := FGPIO
end;

function TDCF77Clock.GetTimer: TTimer;
begin
  if not Assigned(FTimer) then begin
    FTimer := TTimer.Create(Self);
    FTimer.Interval := 50;
    FTimer.OnTimer := @CheckInput;
  end;
  Result := FTimer
end;

procedure TDCF77Clock.CountPulse;
begin
  if Pulse = 19 then Pulse := 0 else Inc(Pulse)
end;

function TDCF77Clock.GetActiveLow: Boolean;
begin
  Result := Input.ActiveLow;
end;

function TDCF77Clock.GetInputAddr: TGPIOAddress;
begin
  Result := Input.Address;
end;

procedure TDCF77Clock.CheckInput(Sender: TObject);
begin
  CountPulse;
  FBit := Input.Value;
  case ClockState of
    csSyncSecStart: begin
        if Bit then Pulse := 0;
        ClockState := csCheckSecStart
      end;
    csCheckSecStart: begin
          if Bit and (Pulse in [0, 1, 2, 3]) then ClockState := csSyncMin
          else ClockState := csSyncSecStart
      end;
    csSyncMin: begin
        if not Bit and (Pulse in [0, 1]) then Sec := 59;
        ClockState := csCountSecond;
      end;
    csCountSecond: begin
        if Bit and (Pulse in [0, 1]) then begin
          IncSec;
          ClockState := csPrepBit
        end
      end;
    csPrepBit: begin
        case Current.Sec of
          20: if not Bit and (Pulse in [2, 3]) then ClockState := csSyncSecStart;
        end
      end;
    csSetTime: begin
        if Bit and (Pulse in [0, 1]) then CountSec;

      end;
  end;
end;

procedure TDCF77Clock.SetActiveLow(const AValue: Boolean);
begin
  Input.ActiveLow := AValue
end;

procedure TDCF77Clock.SetInputAddr(const AValue: TGPIOAddress);
begin
  Input.Address := AValue
end;

end.
