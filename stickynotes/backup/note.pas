unit note;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, Process;

type

  { TNoteForm }

  TNoteForm = class(TForm)
    ImageList1: TImageList;
    Memo1: TMemo;
    Shape1: TShape;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormShow(Sender: TObject);
    procedure AddNote;
    procedure SNPaint;
    procedure Shape1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure SpeedButton3Click(Sender: TObject);

  private
    FPosX, FPosY: integer;  //перемещение формы
    //Фиксация клика ЛКМ для исключения мерцания
    MPress: boolean;

  public

  end;

var
  NoteForm: TNoteForm;

implementation

{$R *.lfm}

{ TNoteForm }

//StartCommand
procedure TNoteForm.AddNote;
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(StringReplace(Application.ExeName, ' ',
      '\ ', [rfReplaceAll, rfIgnoreCase]));
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Перерисовка региона формы
procedure TNoteForm.SNPaint;
var
  ABitmap: TBitmap;
  Points: array of TPoint;
begin
  ABitmap := TBitmap.Create;
  ABitmap.Monochrome := True;
  ABitmap.Width := NoteForm.Width;
  ABitmap.Height := NoteForm.Height;
  SetLength(Points, 5);
  Points[0] := Point(0, 0);
  Points[1] := Point(ABitmap.Width, 0);
  Points[2] := Point(ABitmap.Width, ABitmap.Height - 32);
  Points[3] := Point(ABitmap.Width - 32, ABitmap.Height);
  Points[4] := Point(0, ABitmap.Height);

  with ABitmap.Canvas do
  begin
    Brush.Color := clBlack; // transparent color
    FillRect(0, 0, ABitmap.Width, ABitmap.Height);
    Brush.Color := clWhite; // mask color
    Polygon(Points);
  end;
  NoteForm.SetShape(ABitmap);
  ABitmap.Free;
end;


procedure TNoteForm.Shape1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
    if Shift = [ssLeft] then
  begin
    NoteForm.Width := NoteForm.Width + X;
    NoteForm.Height := NoteForm.Height + Y;

    //Фиксация минимального размера
    if NoteForm.Width < 250 then
      NoteForm.Width := 250;
    if NoteForm.Height < 150 then
      NoteForm.Height := 150;

    //Перерисовка
    SNPaint;
  end;
end;

procedure TNoteForm.SpeedButton3Click(Sender: TObject);
begin
  NoteForm.Close;
end;


procedure TNoteForm.FormShow(Sender: TObject);
begin
  SNPaint;
end;

procedure TNoteForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  FPosX := X;
  FPosY := Y;
  MPress := True;
end;

procedure TNoteForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  if MPress then
  begin
    Left := Left - FPosX + X;
    Top := Top - FPosY + Y;
  end;
end;

procedure TNoteForm.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  MPress := False;
end;

end.


