unit settings_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    ColorButton1: TColorButton;
    procedure ColorButton1ColorChanged(Sender: TObject);
  private

  public

  end;

var
  SettingsForm: TSettingsForm;

implementation
      uses
        note_unit;
{$R *.lfm}

{ TSettingsForm }

procedure TSettingsForm.ColorButton1ColorChanged(Sender: TObject);
begin
  NoteForm.Color:=ColorButton1.ButtonColor;
end;

end.

