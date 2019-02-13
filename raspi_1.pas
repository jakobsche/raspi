{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit raspi_1;

interface

uses
  GPIO, ChipTemp, LEDView, SysFS, Retain, DCF77, LED7SD, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('GPIO', @GPIO.Register);
  RegisterUnit('ChipTemp', @ChipTemp.Register);
  RegisterUnit('LEDView', @LEDView.Register);
  RegisterUnit('DCF77', @DCF77.Register);
  RegisterUnit('LED7SD', @LED7SD.Register);
end;

initialization
  RegisterPackage('raspi_1', @Register);
end.
