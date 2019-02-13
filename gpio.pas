{
 /***************************************************************************
                                   gpio.pas
                                   ------------


 ***************************************************************************/

 *****************************************************************************
  This file is part of the Lazarus packages by Andreas Jakobsche

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit GPIO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

{$DEFINE BPLUS}

const
  NC = 32; {not connected = no related port}

type

  TPortDirection = (pdInput, pdOutput, pdOutputHigh, pdOutputLow);
  TGPIOAddress = 0..NC;
  TEdge = (eRising, eFalling);
  TEdges = set of TEdge;

  { TGPIOPort }

  TGPIOPort = class(TComponent)
  private
    function GetPortEdgeFileName: string;
    procedure GPIOEventRequest(var Msg); message 'GPIOEvent';
  private
    FAddress: TGPIOAddress;
    FValue: Boolean;
    FOnGPIOEvent: TNotifyEvent;
    function GetActiveLow: Boolean;
    function GetActiveLowFilename: string;
    function GetDirection: TPortDirection;
    function GetEdges: TEdges;
    procedure SetEdges(Value: TEdges);
    function GetPortDirName: string;
    function GetPortDirectionFileName: string;
    function GetPortValueFileName: string;
    {function GetTerminal: Byte;}
    function GetValue: Boolean;
    procedure ForcePortFS;
    procedure SetActiveLow(Value: Boolean);
    {procedure SetTerminal(Value: Byte);}
    procedure SetValue(Value: Boolean);
    procedure SetDirection(Value: TPortDirection);
    property ActiveLowFilename: string read GetActiveLowFileName;
    property PortDirName: string read GetPortDirName;
    property PortDirectionFileName: string read GetPortDirectionFileName;
    property PortEdgeFileName: string read GetPortEdgeFileName;
    property PortValueFileName: string read GetPortValueFileName;
  protected
    procedure DoGPIOEvent; virtual;
  public
    {property Terminal: Byte read GetTerminal write SetTerminal;}
    constructor Create(TheOwner: TComponent); override;
    function EdgeFalling: Boolean;
    function EdgeRising: Boolean;
    property Value: Boolean read GetValue write SetValue;
  published
    property ActiveLow: Boolean read GetActiveLow write SetActiveLow;
    property Address: TGPIOAddress read FAddress write FAddress;
    property Direction: TPortDirection read GetDirection write SetDirection;
    property Edges: TEdges read GetEdges write SetEdges;
    property OnGPIOEvent: TNotifyEvent read FOnGPIOEvent write FOnGPIOEvent;
  end;

procedure Register;

implementation

uses sysfs, Patch;

const
  ExportFileName      = '/sys/class/gpio/export';
  UnExportFileName    = '/sys/class/gpio/unexport';
  PortDirNameTemplate = '/sys/class/gpio/gpio%d';

type
  TJ8PinNumbers = 0..106; {0 = not connected}
  TGPIOPins = array[TGPIOAddress] of TJ8PinNumbers;

const
{$IFDEF REV1}
  GPIOPins: TGPIOPins = (
{   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15}      {GPIO}
    3,  5,  0,  0,  7,  0,  0, 26, 24, 21, 19, 23,  0,  0,  8, 10,      {Pin}
{  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31}      {GPIO}
    0, 11, 12,  0,  0, 13, 15, 16, 18, 22,  0,  0,103,104,105,106);     {PIN}
{$ENDIF}
{$IFDEF REV2}
  GPIOPins: TGPIOPins = (
{    0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15}     {GPIO}
     0,  0,  3,  5,  7, 29, 31, 26, 24, 21, 19, 23, 32, 33,  8, 10,     {Pin}
{   16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32} {GPIO}
    36, 11, 12,  0,  0,  0, 15, 16, 18, 22,  0, 13,103,104,105,106,  0);{Pin}
{$ENDIF}
{$IFDEF BPLUS}
  GPIOPins: TGPIOPins = (
{    0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15}     {GPIO}
     0,  0,  3,  5,  7,  0,  0, 26, 24, 21, 19, 23,  0,  0,  8, 10,     {Pin}
{   16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32} {GPIO}
     0, 11, 12, 35, 38, 40, 15, 16, 18, 22, 37, 13,103,104,105,106,  0);{Pin}
{$ENDIF}

{var
  GPIOs: array[TJ8PinNumbers] of TGPIOAddress;}

function TGPIOPort.GetPortEdgeFileName: string;
begin
  ForcePortFS;
  Result := BuildFileName(PortDirName, 'edge')
end;

procedure TGPIOPort.GPIOEventRequest(var Msg);
type
  TGPIOMessage = record
    Msg: ShortString;
    Address: Integer;
  end;
begin
  if TGPIOMessage(Msg).Address = Address then DoGPIOEvent;
end;

function TGPIOPort.GetActiveLow: Boolean;
begin
  ForcePortFS;
  if GetIntAttribute(ActiveLowFileName) = 0 then Result := False
  else Result := True
end;

function TGPIOPort.GetActiveLowFilename: string;
begin
  Result := BuildFileName(PortDirName, 'active_low');
end;

function TGPIOPort.GetPortDirName: string;
begin
  Result := Format(PortDirNameTemplate, [FAddress])
end;

function TGPIOPort.GetPortDirectionFileName: string;
begin
  Result := BuildFileName(PortDirName, 'direction')
end;

function TGPIOPort.GetPortValueFileName: string;
begin
  Result := BuildFilename(PortDirname, 'value')
end;

{function TGPIOPort.GetTerminal: Byte;
begin
  Result := GPIOPins[Address]
end;}

function TGPIOPort.GetValue: Boolean;
begin
  ForcePortFS;
  case Direction of
    pdInput: FValue := GetBooleanAttribute(PortValueFileName)
  end;
  Result := FValue;
end;

procedure TGPIOPort.ForcePortFS;
var F: TextFile;
begin
  if not FileExists(PortDirName) then begin
    AssignFile(F, ExportFilename);
    Rewrite(F);
    Write(F, FAddress);
    CloseFile(F)
  end;
end;

procedure TGPIOPort.SetActiveLow(Value: Boolean);
begin
  ForcePortFS;
  SetAttribute(ActiveLowFileName, Value);
end;

{procedure TGPIOPort.SetTerminal(Value: Byte);
begin
  FAddress := GPIOs[Value]
end;}

procedure TGPIOPort.SetValue(Value: Boolean);
begin
  ForcePortFS;
  FValue := Value;
  if Direction = pdOutput then begin
    SetAttribute(PortValueFileName, FValue);
  end;
end;

function TGPIOPort.GetDirection: TPortDirection;
var
  x: string;
begin
  Result := pdInput;
  ForcePortFS;
  x := GetAttribute(PortDirectionFileName);
  if x <> 'in' then Result := pdOutput
end;

function TGPIOPort.GetEdges: TEdges;
var
  x: string;
begin
  Result := [];
  x := GetAttribute(PortEdgeFileName);
  if x = 'rising' then Result := [eRising]
  else if x = 'falling' then Result := [eFalling]
  else if x = 'both' then Result := [erising, eFalling]
end;

procedure TGPIOPort.SetEdges(Value: TEdges);
begin
  ForcePortFS;
  if Value = [eRising] then SetAttribute(PortEdgeFileName, 'rising')
  else if Value = [eFalling] then SetAttribute(PortEdgeFileName, 'falling')
  else if Value = [eRising, eFalling] then SetAttribute(PortEdgeFileName, 'both')
  else SetAttribute(PortEdgeFileName, 'none')
  {Ein-/Ausschließen von Callbacks ist noch erforderlich
  (udev-Regeln? uevent?)}
end;

procedure TGPIOPort.SetDirection(Value: TPortDirection);
begin
  ForcePortFS;
  case Value of
    pdOutput: SetAttribute(PortDirectionFileName, 'out');
    pdOutputHigh: SetAttribute(PortDirectionFileName, 'high');
    pdOutputLow: SetAttribute(PortDirectionFileName, 'low');
    else SetAttribute(PortDirectionFileName,  'in');
  end;
end;

procedure TGPIOPort.DoGPIOEvent;
begin
  if Assigned(OnGPIOEvent) then OnGPIOEvent(Self)
end;

constructor TGPIOPort.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FAddress := NC;
end;

function TGPIOPort.EdgeFalling: Boolean;
begin
  Result := Value = False
end;

function TGPIOPort.EdgeRising: Boolean;
begin
  Result := Value = True
end;

procedure Register;
begin
  RegisterComponents('Hardware', [TGPIOPort]);
end;

{var
  i: TGPIOAddress;

initialization

for i := Low(TGPIOAddress) to High(TGPIOAddress) do
  if GPIOPins[i] <> 0 then GPIOs[GPIOPins[i]] := i
  else GPIOs[i] := 32 }

end.

