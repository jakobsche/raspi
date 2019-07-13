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
  Classes, SysUtils, EvMsg;

{$DEFINE BPLUS}

const
  NC = 32; {not connected = no related port}

type

  TPortDirection = (pdInput, pdOutput, pdOutputHigh, pdOutputLow);
  TGPIOAddress = 0..NC;
  TEdge = (eRising, eFalling);
  TEdges = set of TEdge;

  { TCustomGPIOPort }

  TCustomGPIOPort = class(TComponent)
  private
    procedure GPIOEventRequest(var Msg); message 'GPIOEvent';
  private
    FAddress: TGPIOAddress;
    FValue: Boolean;
    FOnGPIOEvent: TNotifyEvent;
    function GetActiveLow: Boolean;
    function GetDirection: TPortDirection;
    procedure SetActiveLow(AValue: Boolean);
    function GetActiveLowFilename: string;
    function GetEdges: TEdges; virtual;
    procedure SetDirection(AValue: TPortDirection);
    procedure SetEdges(Value: TEdges); virtual;
    function GetPortDirName: string;
    function GetPortDirectionFileName: string;
    function GetPortEdgeFileName: string;
    function GetPortValueFileName: string;
    function GetValue: Boolean;
    procedure SetValue(Value: Boolean);
    procedure ForcePortFS;
    property ActiveLowFilename: string read GetActiveLowFileName;
    property PortDirName: string read GetPortDirName;
    property PortDirectionFileName: string read GetPortDirectionFileName;
    property PortEdgeFileName: string read GetPortEdgeFileName;
    property PortValueFileName: string read GetPortValueFileName;
  protected
    procedure DoGPIOEvent; virtual;
    property ActiveLow: Boolean read GetActiveLow write SetActiveLow;
    property Direction: TPortDirection read GetDirection write SetDirection;
    property Edges: TEdges read GetEdges write SetEdges; {sets also MessageGenerator, if it is nil}
    property Value: Boolean read GetValue write SetValue;
  public
  published
    property Address: TGPIOAddress read FAddress write FAddress;
  end;

  TBinaryIO = class(TCustomGPIOPort)
  public

  end;

  TBinaryInput = class(TBinaryIO)
  public
    constructor Create(AnOwner: TComponent); override;
    property Value: Boolean read GetValue;
  end;

  { TBinaryOutput }

  TBinaryOutput = class(TBinaryIO)
  public
    constructor Create(AnOwner: TComponent); override;
    property Value: Boolean write SetValue;
  end;

  { TEdgeDrivenInput }

  TEdgeDrivenInput = class(TBinaryInput, IMessageReceiver)
  private
    class var FMessageGenerator: TMessageGenerator;
    function GetEdgeFalling: Boolean;
    function GetEdgeRising: Boolean;
  private
    FEdges: TEdges;
    FOnEdge, FOnFallingEdge, FOnRisingEdge: TNotifyEvent;
    PrevValue: Boolean;
    function GetEdges: TEdges; override;
    function GetMessageGenerator: TMessageGenerator;
    procedure SetEdges(AValue: TEdges); override; {connects to FMessageGenerator, if
      Value <> [] oder disconnects, if AValue = []}
    procedure SetMessageGenerator(AValue: TMessageGenerator);
    property EdgeRising: Boolean read GetEdgeRising;
    property EdgeFalling: Boolean read GetEdgeFalling;
  protected
    procedure EdgeEvent; virtual;
    procedure RisingEdgeEvent; virtual;
    procedure FallingEdgeEvent; virtual;
  public
    destructor Destroy; override;
    procedure GenerateEvents; virtual;
    property MessageGenerator: TMessageGenerator read GetMessageGenerator
      write SetMessageGenerator; {Ignore this property, if this is the
      only class you want to connect to a thread and all its instances use the
      same thread instance. Assign this to the same property of another class,
      after Edges is assigned to something <> [], if a further class is supposed
      to use the same thread. Alternatively create a TMessageGenerator
      instance and assign it to 1 instance of every classes (or the classes
      themselves) that will have to use the same thread instance.}
  published
    property Edges; {sets also MessageGenerator, if it is nil}
    property OnEdge: TNotifyEvent read FOnEdge write FOnEdge;
    property OnFallingEdge: TNotifyEvent read FOnFallingEdge write FOnFallingEdge;
    property OnRisingEdge: TNotifyEvent read FOnRisingEdge write FOnRisingEdge;
  end;

  { TGPIOPort }

  TGPIOPort = class(TCustomGPIOPort)
  private
    {function GetTerminal: Byte;}
    {procedure SetTerminal(Value: Byte);}
  protected
  public
    {property Terminal: Byte read GetTerminal write SetTerminal;}
    constructor Create(TheOwner: TComponent); override;
    function EdgeFalling: Boolean;
    function EdgeRising: Boolean;
  published
    property ActiveLow;
    property Direction;
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

{ TBinaryOutput }

constructor TBinaryOutput.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  Direction := pdOutput
end;

{ TEdgeDrivenInput }

function TEdgeDrivenInput.GetEdgeFalling: Boolean;
begin
  Result := False
end;

function TEdgeDrivenInput.GetEdgeRising: Boolean;
begin
  Result := False
end;

function TEdgeDrivenInput.GetEdges: TEdges;
begin
  Result := FEdges;
end;

function TEdgeDrivenInput.GetMessageGenerator: TMessageGenerator;
begin
  Result := FMessageGenerator
end;

procedure TEdgeDrivenInput.SetEdges(AValue: TEdges);
begin
  if AValue <> FEdges then begin
    if FEdges = [] then begin
      if not Assigned(FMessageGenerator) then
        FMessageGenerator := TMessageGenerator.Create(not (csDesigning in ComponentState));
      while not FMessageGenerator.AddReceiver(Self) do;
    end
    else
      if AValue = [] then begin
        while not FMessageGenerator.RemoveReceiver(Self) do;
        if FMessageGenerator.ReceiverCount = 0 then FreeAndNil(FMessageGenerator)
      end;
    FEdges := AValue
  end
end;

procedure TEdgeDrivenInput.SetMessageGenerator(AValue: TMessageGenerator);
begin
  if AValue <> FMessageGenerator then begin
    if Assigned(FMessageGenerator) then while not FMessageGenerator.RemoveReceiver(Self) do;
    if FMessageGenerator.ReceiverCount = 0 then FMessageGenerator.Free;
    FMessageGenerator := AValue;
    while FMessageGenerator.AddReceiver(Self) do
  end;
end;

procedure TEdgeDrivenInput.EdgeEvent;
begin
  if Assigned(FOnEdge) then FOnEdge(Self)
end;

procedure TEdgeDrivenInput.RisingEdgeEvent;
begin
  if Assigned(FOnRisingEdge) then FOnRisingEdge(Self)
end;

procedure TEdgeDrivenInput.FallingEdgeEvent;
begin
  if Assigned(FOnFallingEdge) then FOnFallingEdge(Self)
end;

destructor TEdgeDrivenInput.Destroy;
begin
  while not FMessageGenerator.RemoveReceiver(Self) do;
  if FMessageGenerator.ReceiverCount = 0 then FMessageGenerator.Free;
  inherited Destroy;
end;

procedure TEdgeDrivenInput.GenerateEvents;
begin
  if Edges <> [] then begin
    if Value <> PrevValue then begin
      if (eRising in Edges) and EdgeRising then RisingEdgeEvent;
      if (eFalling in Edges) and EdgeFalling then FallingEdgeEvent;
      if (Edges = [eRising, eFalling]) and (EdgeRising or EdgeFalling) then
        EdgeEvent
    end;
    PrevValue := FValue
  end;
end;

{ TBinaryInput }

constructor TBinaryInput.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  Direction := pdInput;
end;

{var
  GPIOs: array[TJ8PinNumbers] of TGPIOAddress;}

function TCustomGPIOPort.GetPortEdgeFileName: string;
begin
  ForcePortFS;
  Result := BuildFileName(PortDirName, 'edge')
end;

procedure TCustomGPIOPort.GPIOEventRequest(var Msg);
type
  TGPIOMessage = record
    Msg: ShortString;
    Address: Integer;
  end;
begin
  if TGPIOMessage(Msg).Address = Address then DoGPIOEvent;
end;

function TCustomGPIOPort.GetActiveLow: Boolean;
begin
  ForcePortFS;
  if GetIntAttribute(ActiveLowFileName) = 0 then Result := False
  else Result := True
end;

function TCustomGPIOPort.GetActiveLowFilename: string;
begin
  Result := BuildFileName(PortDirName, 'active_low');
end;

function TCustomGPIOPort.GetPortDirName: string;
begin
  Result := Format(PortDirNameTemplate, [FAddress])
end;

function TCustomGPIOPort.GetPortDirectionFileName: string;
begin
  Result := BuildFileName(PortDirName, 'direction')
end;

function TCustomGPIOPort.GetPortValueFileName: string;
begin
  Result := BuildFilename(PortDirname, 'value')
end;

{function TGPIOPort.GetTerminal: Byte;
begin
  Result := GPIOPins[Address]
end;}

function TCustomGPIOPort.GetValue: Boolean;
begin
  ForcePortFS;
  case Direction of
    pdInput: FValue := GetBooleanAttribute(PortValueFileName)
  end;
  Result := FValue;
end;

procedure TCustomGPIOPort.ForcePortFS;
var F: TextFile;
begin
  if not FileExists(PortDirName) then begin
    AssignFile(F, ExportFilename);
    Rewrite(F);
    Write(F, FAddress);
    CloseFile(F)
  end;
end;

procedure TCustomGPIOPort.DoGPIOEvent;
begin

end;

procedure TCustomGPIOPort.SetActiveLow(AValue: Boolean);
begin
  ForcePortFS;
  SetAttribute(ActiveLowFileName, AValue);
end;

{procedure TGPIOPort.SetTerminal(Value: Byte);
begin
  FAddress := GPIOs[Value]
end;}

procedure TCustomGPIOPort.SetValue(Value: Boolean);
begin
  ForcePortFS;
  FValue := Value;
  if Direction = pdOutput then begin
    SetAttribute(PortValueFileName, FValue);
  end;
end;

function TCustomGPIOPort.GetDirection: TPortDirection;
var
  x: string;
begin
  Result := pdInput;
  ForcePortFS;
  x := GetAttribute(PortDirectionFileName);
  if x <> 'in' then Result := pdOutput
end;

function TCustomGPIOPort.GetEdges: TEdges;
var
  x: string;
begin
  Result := [];
  x := GetAttribute(PortEdgeFileName);
  if x = 'rising' then Result := [eRising]
  else if x = 'falling' then Result := [eFalling]
  else if x = 'both' then Result := [erising, eFalling]
end;

procedure TCustomGPIOPort.SetEdges(Value: TEdges);
begin
  ForcePortFS;
  if Value = [eRising] then SetAttribute(PortEdgeFileName, 'rising')
  else if Value = [eFalling] then SetAttribute(PortEdgeFileName, 'falling')
  else if Value = [eRising, eFalling] then SetAttribute(PortEdgeFileName, 'both')
  else SetAttribute(PortEdgeFileName, 'none')
  {Ein-/Ausschließen von Callbacks ist noch erforderlich
  (udev-Regeln? uevent?)}
end;

procedure TCustomGPIOPort.SetDirection(AValue: TPortDirection);
begin
  ForcePortFS;
  case AValue of
    pdOutput: SetAttribute(PortDirectionFileName, 'out');
    pdOutputHigh: SetAttribute(PortDirectionFileName, 'high');
    pdOutputLow: SetAttribute(PortDirectionFileName, 'low');
    else SetAttribute(PortDirectionFileName,  'in');
  end;
end;

{procedure TCustomGPIOPort.DoGPIOEvent;
begin
  if Assigned(OnGPIOEvent) then OnGPIOEvent(Self)
end;}

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
  RegisterComponents('Hardware', [TBinaryInput, TEdgeDrivenInput, TBinaryOutput,
  TGPIOPort]);
end;

{var
  i: TGPIOAddress;

initialization

for i := Low(TGPIOAddress) to High(TGPIOAddress) do
  if GPIOPins[i] <> 0 then GPIOs[GPIOPins[i]] := i
  else GPIOs[i] := 32 }

end.

