{
 /***************************************************************************
                                   led7sd.pas
                                   ----------


 ***************************************************************************/

 *****************************************************************************
  This file is part of the Lazarus packages by Andreas Jakobsche

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit LED7SD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GPIO;

type

  TBitIndex = 0..3;
  TDigitIndex = 1..4;
  TLatchGPIOList = array[TDigitIndex] of TGPIOPort;
  TDataGPIOList = array[TBitIndex] of TGPIOPort;

  { TBCDOutput4Digits }

  TBCDOutput4Digits = class(TComponent)
  private
    { Private declarations }
    FDataGPIOs: TDataGPIOList;
    FLatchGPIOs: TLatchGPIOList;
    FText: string;
    function GetDataGPIOs(AnIndex: TBitIndex): TGPIOPort;
    function GetLatchGPIOs(AnIndex: TDigitIndex): TGPIOPort;
    function GetA: Boolean;
    function GetB: Boolean;
    function GetC: Boolean;
    function GetD: Boolean;
    function GetLE(AnIndex: TDigitIndex): Boolean;
    procedure SetA(AValue: Boolean);
    procedure SetB(AValue: Boolean);
    procedure SetC(AValue: Boolean);
    procedure SetD(AValue: Boolean);
    procedure SetLE(AnIndex: TDigitIndex; AValue: Boolean);
    property DataGPIOs[AnIndex: TBitIndex]: TGPIOPort read GetDataGPIOs;
    property LatchGPIOs[AnIndex: TDigitIndex]: TGPIOPort read GetLatchGPIOs;
    function GetPortA: Integer;
    function GetPortB: Integer;
    function GetPortC: Integer;
    function GetPortD: Integer;
    procedure SetPortA(AValue: Integer);
    procedure SetPortB(AValue: Integer);
    procedure SetPortC(AValue: Integer);
    procedure SetPortD(AValue: Integer);
    procedure SetText(AValue: string);
    procedure UpdateDisplay;
    property A: Boolean read GetA write SetA;
    property B: Boolean read GetB write SetB;
    property C: Boolean read GetC write SetC;
    property D: Boolean read GetD write SetD;
    property LE[AnIndex: TDigitIndex]: Boolean read GetLE write SetLE;
  protected
    { Protected declarations }
  public
    { Public declarations }
  published
    { Published declarations }
    property PortA: Integer read GetPortA write SetPortA;
    property PortB: Integer read GetPortB write SetPortB;
    property PortC: Integer read GetPortC write SetPortC;
    property PortD: Integer read GetPortD write SetPortD;
    property Text: string read FText write SetText;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Hardware',[TBCDOutput4Digits]);
end;

{ TBCDOutput4Digits }

function TBCDOutput4Digits.GetDataGPIOs(AnIndex: TBitIndex): TGPIOPort;
begin
  if not Assigned(FDataGPIOs[AnIndex]) then begin
    FDataGPIOs[AnIndex] := TGPIOPort.Create(Self);
    with FDataGPIOs[AnIndex] do begin
      Direction := pdOutput
    end;
  end;
  Result := FDataGPIOs[AnIndex]
end;

function TBCDOutput4Digits.GetLatchGPIOs(AnIndex: TDigitIndex): TGPIOPort;
begin
  if not Assigned(FLatchGPIOs[AnIndex]) then begin
    FLatchGPIOs[AnIndex] := TGPIOPort.Create(Self);
    with FLatchGPIOs[AnIndex] do begin
      Direction := pdOutputHigh
    end;
  end;
  Result := FLatchGPIOs[AnIndex]
end;

function TBCDOutput4Digits.GetLE(AnIndex: TDigitIndex): Boolean;
begin
  Result := LatchGPIOs[AnIndex].Value;
end;

function TBCDOutput4Digits.GetA: Boolean;
begin
  Result := DataGPIOs[0].Value
end;

function TBCDOutput4Digits.GetB: Boolean;
begin
  Result := DataGPIOs[1].Value
end;

function TBCDOutput4Digits.GetC: Boolean;
begin
  Result := DataGPIOs[2].Value
end;

function TBCDOutput4Digits.GetD: Boolean;
begin
  Result := DataGPIOs[3].Value
end;

procedure TBCDOutput4Digits.SetA(AValue: Boolean);
begin
  DataGPIOs[0].Value := AValue;
end;

procedure TBCDOutput4Digits.SetB(AValue: Boolean);
begin
  DataGPIOs[1].Value := AValue;
end;

procedure TBCDOutput4Digits.SetC(AValue: Boolean);
begin
  DataGPIOs[2].Value := AValue;
end;

procedure TBCDOutput4Digits.SetD(AValue: Boolean);
begin
  DataGPIOs[3].Value := AValue;
end;

procedure TBCDOutput4Digits.SetLE(AnIndex: TDigitIndex; AValue: Boolean);
begin
  LatchGPIOs[AnIndex].Value := AValue
end;

procedure TBCDOutput4Digits.SetText(AValue: string);
begin
  if FText=AValue then Exit;
  FText:=AValue;
  UpdateDisplay
end;

function TBCDOutput4Digits.GetPortA: Integer;
begin
  Result := DataGPIOs[0].Address;
end;

function TBCDOutput4Digits.GetPortB: Integer;
begin
  Result := DataGPIOs[1].Address
end;

function TBCDOutput4Digits.GetPortC: Integer;
begin
  Result := DataGPIOs[2].Address
end;

function TBCDOutput4Digits.GetPortD: Integer;
begin
  Result := DataGPIOs[3].Address
end;

procedure TBCDOutput4Digits.SetPortA(AValue: Integer);
begin
  DataGPIOs[0].Address:= AValue;
end;

procedure TBCDOutput4Digits.SetPortB(AValue: Integer);
begin
  DataGPIOs[1].Address := AValue
end;

procedure TBCDOutput4Digits.SetPortC(AValue: Integer);
begin
  DataGPIOs[2].Address := AValue
end;

procedure TBCDOutput4Digits.SetPortD(AValue: Integer);
begin
  DataGPIOs[3].Address := AValue
end;

procedure TBCDOutput4Digits.UpdateDisplay;
var
  x: Byte;
  i: TDigitIndex;
begin
  for i := Low(TDigitIndex) to High(TDigitIndex) do begin
    x := Ord(Text[i]) - Ord('0');
    if (x >= 0) and (x <= 9) then begin
      A := x and 1 <> 0;
      B := x and 2 <> 0;
      C := x and 4 <> 0;
      D := x and 8 <> 0;
      {Sleep(1); eventuell einfügen}
      LE[i] := False;
      {Sleep(1); eventuell einfügen}
      LE[i] := True;
    end;
  end;
end;

end.
