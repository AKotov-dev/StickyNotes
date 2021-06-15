unit note_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, IniPropStorage, DefaultTranslator;

type

  { TNoteForm }

  TNoteForm = class(TForm)
    ColorDialog1: TColorDialog;
    FontDialog1: TFontDialog;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    Memo1: TMemo;
    Shape1: TShape;
    SpeedButton2: TSpeedButton;
    CloseBtn: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure FormShow(Sender: TObject);
    procedure Memo1KeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure Memo1MouseLeave(Sender: TObject);
    procedure Shape1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure CloseBtnClick(Sender: TObject);
    procedure Shape1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure SNPaint;
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);

  private
    FPosX, FPosY: integer;  //перемещение формы
    //Фиксация клика ЛКМ для исключения мерцания
    MPress: boolean;

  public
    destructor Destroy; override;

  end;

resourcestring
  SDeleteNote = 'Delete this note?';
  SNoteNumber = 'Note';

var
  NoteForm: TNoteForm;

implementation

uses unit1;

{$R *.lfm}

{ TNoteForm }

//Чистое удаление экземпляра
destructor TNoteForm.Destroy;
begin
  inherited;
  Self := nil; // <---
end;

procedure TNoteForm.FormShow(Sender: TObject);
begin
  //Ищем файл содержимого записки Self и применяем к форме + создание, если отсутствует
  IniPropStorage1.IniFileName :=
    GetUserDir + '.config/stickynotes/' + Self.Name;
  IniPropStorage1.Restore;
  //Штамп времени
  if not FileExists(GetUserDir + '.config/stickynotes/' + Self.Name) then
    Memo1.Lines.Add(StringReplace(Self.Name, 'NoteForm', SNoteNumber,
      [rfReplaceAll, rfIgnoreCase]) + ': ' +
      FormatDateTime('dd mmmm yyyy - hh:nn:ss', Now));

  IniPropStorage1.Save;

  //Каретка в конец
  Memo1.SelStart := Length(Memo1.Text);
  //IniPropStorage1.Save;

  //Отрисовка загнутого угла
  SNPaint;
end;

procedure TNoteForm.Memo1KeyUp(Sender: TObject; var Key: word; Shift: TShiftState);

begin
  IniPropStorage1.Save;
end;

//Если вставляли из буфера
procedure TNoteForm.Memo1MouseLeave(Sender: TObject);
begin
  IniPropStorage1.Save;
end;

//Перерисовка региона формы
procedure TNoteForm.SNPaint;
var
  ABitmap: TBitmap;
  Points: array of TPoint;
begin
  ABitmap := TBitmap.Create;
  ABitmap.Monochrome := True;
  ABitmap.Width := Width;
  ABitmap.Height := Height;
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
  SetShape(ABitmap);
  ABitmap.Free;
end;

procedure TNoteForm.SpeedButton2Click(Sender: TObject);
begin
  MainForm.NewNoteItem.Click;
end;

//Цвет заметки
procedure TNoteForm.SpeedButton4Click(Sender: TObject);
begin
  ColorDialog1.Color := Color;
  if ColorDialog1.Execute then
  begin
    Color := ColorDialog1.Color;
    Shape1.Brush.Color := Color;
    IniPropStorage1.Save;
  end;
end;

//Удаление заметки
procedure TNoteForm.SpeedButton5Click(Sender: TObject);
begin
  if MessageDlg(SDeleteNote, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Close;
    DeleteFile(GetUserDir + '.config/stickynotes/' + Self.Name);
  end;
end;

//Шрифт заметки
procedure TNoteForm.SpeedButton6Click(Sender: TObject);
begin
  FontDialog1.Font := Memo1.Font;
  if FontDialog1.Execute then
  begin
    Memo1.Font := FontDialog1.Font;
    IniPropStorage1.Save;
  end;
end;

//Цвет шрифта заметки
procedure TNoteForm.SpeedButton7Click(Sender: TObject);
begin
  ColorDialog1.Color := Memo1.Font.Color;
  if ColorDialog1.Execute then
  begin
    Memo1.Font.Color := ColorDialog1.Color;
    IniPropStorage1.Save;
  end;
end;

//Изменение размера заметки
procedure TNoteForm.Shape1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  if Shift = [ssLeft] then
  begin
    if Mouse.CursorPos.x <= Screen.Width - 50 then
      Width := Width + X
    else
      Left := Screen.Width - Width;

    if Mouse.CursorPos.y <= Screen.Height - 100 then
      Height := Height + Y
    else
      Top := Screen.Height - Height;

    //Фиксация минимального размера по длине
    if Width < 250 then
      Width := 250;
    //Фиксация минимального размера по высоте
    if Height < 150 then
      Height := 150;

    //Перерисовка
    SNPaint;
  end;
end;

procedure TNoteForm.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TNoteForm.Shape1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  IniPropStorage1.Save;
end;

procedure TNoteForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  FPosX := X;
  FPosY := Y;
  MPress := True;
end;

procedure TNoteForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Closeaction := caFree;
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
  IniPropStorage1.Save;
end;

end.
