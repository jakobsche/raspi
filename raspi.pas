{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit raspi;

interface

uses
  GPIO, LED7SD, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('GPIO', @GPIO.Register);
  RegisterUnit('LED7SD', @LED7SD.Register);
end;

initialization
  RegisterPackage('raspi', @Register);
end.
