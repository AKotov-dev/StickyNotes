unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Buttons, Menus, IniPropStorage, FileUtil, Process;

type

  { TMainForm }

  TMainForm = class(TForm)
    ExitItem: TMenuItem;
    AboutItem: TMenuItem;
    FontDialog1: TFontDialog;
    Image1: TImage;
    Image2: TImage;
    IniPropStorage1: TIniPropStorage;
    FontItem: TMenuItem;
    TransparencyItem: TMenuItem;
    N6: TMenuItem;
    N5: TMenuItem;
    NewNoteItem: TMenuItem;
    ExportItem: TMenuItem;
    ImportItem: TMenuItem;
    N4: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ShowAllItem: TMenuItem;
    CloseAllItem: TMenuItem;
    AutoStartItem: TMenuItem;
    N3: TMenuItem;
    N2: TMenuItem;
    N1: TMenuItem;
    PopupMenu1: TPopupMenu;
    TrayIcon1: TTrayIcon;
    procedure AboutItemClick(Sender: TObject);
    procedure ExportItemClick(Sender: TObject);
    procedure FontItemClick(Sender: TObject);
    procedure ImportItemClick(Sender: TObject);
    procedure NewNoteItemClick(Sender: TObject);
    procedure AutoStartItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);
    procedure ShowAllItemClick(Sender: TObject);
    procedure CloseAllItemClick(Sender: TObject);
    procedure ShowAllNotes;
    procedure TransparencyItemClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private

  public

  end;

resourcestring
  SImportTitle = 'Import notes';
  SImportMessage = 'Importing notes completed...';
  SExportTitle = 'Export notes';
  SExportMessage = 'Exporting notes completed...';

var
  MainForm: TMainForm;

implementation

uses note_unit, about_unit;

  {$R *.lfm}

  { TMainForm }

//Количество сохраненных заметок
function GetFilesCount: integer;
var
  SR: TSearchRec;
begin
  Result := 0;
  if FindFirst(GetUserDir + '.config/stickynotes/NoteForm*', faAnyFile, SR) = 0 then
  try
    repeat
      if SR.Attr and faDirectory = 0 then
        Inc(Result)
    until FindNext(SR) <> 0
  finally
    FindClose(SR);
  end;
end;

// Показать все заметки по конфигам
procedure TMainForm.ShowAllNotes;
var
  SR: TSearchRec;
  ANote: TNoteForm;
  // Локальная переменная вместо глобальной
begin
  if FindFirst(GetUserDir + '.config/stickynotes/NoteForm*', faAnyFile, SR) = 0 then
  try
    repeat
      if SR.Attr and faDirectory = 0 then
      begin
        ANote := TNoteForm.Create(Self);
        ANote.Name := SR.Name;

        // Передаем настройки
        ANote.AlphaBlend := MainForm.AlphaBlend;
        ANote.Font.Assign(MainForm.Font);

        // Важно: Настраиваем внутренний компонент Memo самой созданной записки
        ANote.Memo1.ParentColor := False;
        ANote.Memo1.ParentFont := False;
        ANote.Memo1.Font.Assign(MainForm.Font);
        ANote.Memo1.Font.Color := clBlack;

        ANote.Show;
      end;
    until FindNext(SR) <> 0
  finally
    FindClose(SR);
  end;
end;

//Переключение прозрачности всех видимых заметок
procedure TMainForm.TransparencyItemClick(Sender: TObject);
var
  i: integer;
  bmp: TBitmap;
begin
  try
    bmp := TBitmap.Create;
    bmp.PixelFormat := pf32bit;
    bmp.Assign(Image2.Picture.Graphic);

    if not TransparencyItem.Bitmap.Empty then
    begin
      TransparencyItem.Bitmap.Clear;
      MainForm.AlphaBlend := False;
    end
    else
    begin
      TransparencyItem.Bitmap.Assign(bmp);
      MainForm.AlphaBlend := True;
    end;

    IniPropStorage1.Save;

    //Перерисовка всех форм

    for i := 0 to Screen.FormCount - 1 do
      if Pos('NoteForm', Screen.Forms[i].Name) <> 0 then
      begin
        with Screen.Forms[i] do
        begin
          AlphaBlend := MainForm.AlphaBlend;
         { Invalidate;
          Update;
          Repaint;
          Refresh;
          Left := Left - 1;
          Left := Left + 1;}
          Hide;
          Show;
        end;
      end;

    Application.ProcessMessages;

  finally
    bmp.Free;
  end;
end;


//Показать/Скрыть все
procedure TMainForm.TrayIcon1Click(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to Screen.FormCount - 1 do
    if Pos('NoteForm', Screen.Forms[i].Name) <> 0 then
    begin
      CloseAllItem.Click;
      break;
    end
    else
    begin
      ShowAllItem.Click;
      break;
    end;
end;

procedure TMainForm.ExitItemClick(Sender: TObject);
begin
  CloseAllItem.Click;

  Close;
end;

//Показать все
procedure TMainForm.ShowAllItemClick(Sender: TObject);
begin
  //Закрываем все заметки
  CloseAllItem.Click;

  Application.ProcessMessages;   //здесь не освобождалась форма!

  if GetFilesCount <> 0 then
    ShowAllNotes;
end;

procedure TMainForm.CloseAllItemClick(Sender: TObject);
var
  i: integer;
begin
  //Закрываем все заметки
  for i := Screen.FormCount - 1 downto 0 do
    if Pos('NoteForm', Screen.Forms[i].Name) <> 0 then
      Screen.Forms[i].Close;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  bmp: TBitmap;
begin
  // Устраняем баг иконки приложения
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.Assign(Image1.Picture.Graphic);
    Application.Icon.Assign(bmp);

    TrayIcon1.Hint := Application.Title;
    TrayIcon1.Icon := Application.Icon;

    if not DirectoryExists(GetUserDir + '.config') then
      MkDir(GetUserDir + '.config');

    if not DirectoryExists(GetUserDir + '.config/stickynotes') then
      MkDir(GetUserDir + '.config/stickynotes');

    IniPropStorage1.IniFileName := GetUserDir + '.config/stickynotes/settings.conf';
    //Вытаскиваем Default-настройки
    IniPropStorage1.Restore;

    //Контроль автостарта
    bmp.Assign(Image2.Picture.Graphic);

    if FileExists(GetUserDir + '.config/autostart/stickynotes.desktop') then
      AutoStartItem.Bitmap.Assign(bmp);

    //Контроль прозрачности
    if MainForm.AlphaBlend then TransparencyItem.Bitmap.Assign(bmp);

    //Сразу показываем заметки
    ShowAllItem.Click;

  finally
    bmp.Free;
  end;
end;

// Добавить новую записку
procedure TMainForm.NewNoteItemClick(Sender: TObject);
var
  i: integer;
  ANote: TNoteForm; // Локальная переменная
begin
  // Первая записка существует?
  if not FileExists(GetUserDir + '.config/stickynotes/NoteForm') then
  begin
    ANote := TNoteForm.Create(Self);
    ANote.AlphaBlend := MainForm.AlphaBlend;
    ANote.Font.Assign(MainForm.Font);
    ANote.Memo1.ParentFont := False;
    ANote.Memo1.Font.Color := clBlack;
    ANote.Show;
    Exit;
  end;

  for i := 1 to GetFilesCount do
  begin
    if not FileExists(GetUserDir + '.config/stickynotes/NoteForm_' + IntToStr(i)) then
    begin
      ANote := TNoteForm.Create(Self);
      ANote.Name := 'NoteForm_' + IntToStr(i);
      ANote.AlphaBlend := MainForm.AlphaBlend;
      ANote.Font.Assign(MainForm.Font);
      ANote.Memo1.ParentFont := False;
      ANote.Memo1.Font.Color := clBlack;
      ANote.Show;
      Exit;
    end;
  end;
end;

//Экспорт в архив StickyNotes.tar.gz
procedure TMainForm.ExportItemClick(Sender: TObject);
var
  s: ansistring;
begin
  //Закрываем все открытые записки
  CloseAllItem.Click;

  if SaveDialog1.Execute then
  begin
    //Экспорт
    RunCommand('/bin/bash', ['-c', 'tar -czf "' + SaveDialog1.FileName +
      '" -C ~/.config/stickynotes .'], s);

    TrayIcon1.BalloonTitle := SExportTitle;
    TrayIcon1.BalloonHint := SExportMessage;
    TrayIcon1.ShowBalloonHint;
  end;
end;

//Изменение шрифта
procedure TMainForm.FontItemClick(Sender: TObject);
var
  i: integer;
  NForm: TNoteForm;
begin
  Application.ProcessMessages;

  FontDialog1.Font := MainForm.Font;

  if FontDialog1.Execute then
  begin
    MainForm.Font.Assign(FontDialog1.Font);

    for i := 0 to Screen.FormCount - 1 do
    begin
      if Screen.Forms[i] is TNoteForm then
      begin
        NForm := TNoteForm(Screen.Forms[i]);

        NForm.Memo1.Font.Assign(MainForm.Font);
        NForm.Memo1.Font.Color := clBlack;

        NForm.Memo1.Invalidate;
      end;
    end;

    IniPropStorage1.Save;
  end;
end;

procedure TMainForm.AboutItemClick(Sender: TObject);
begin
  AboutForm := TAboutForm.Create(Self);
  AboutForm.Show;
end;

//Импорт записок StickyNotes.tar.gz
procedure TMainForm.ImportItemClick(Sender: TObject);
var
  s: ansistring;
begin
  //Закрываем все открытые записки (диалоги модальны)
  CloseAllItem.Click;

  if OpenDialog1.Execute then
  begin
    //Импорт
    RunCommand('/bin/bash', ['-c', 'rm -f ~/.config/stickynotes/*; tar -xvf "' +
      OpenDialog1.FileName + '" -C ~/.config/stickynotes'], s);

    TrayIcon1.BalloonTitle := SImportTitle;
    TrayIcon1.BalloonHint := SImportMessage;
    TrayIcon1.ShowBalloonHint;

    //Вытаскиваем настройки MainForm (Font и AlphaBlend)
    IniPropStorage1.Restore;
  end;
end;

//Ставим в автозагрузку
procedure TMainForm.AutoStartItemClick(Sender: TObject);
var
  bmp: TBitmap;
begin
  // Устраняем баг иконки приложения
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.Assign(MainForm.Image2.Picture.Graphic);

    if not AutoStartItem.Bitmap.Empty then
      DeleteFile(GetUserDir + '.config/autostart/stickynotes.desktop')
    else
    begin
      if not DirectoryExists(GetUserDir + '.config/autostart') then
        MkDir(GetUserDir + '.config/autostart');

      CopyFile('/usr/share/applications/stickynotes.desktop',
        GetUserDir + '.config/autostart/stickynotes.desktop', False);
    end;

    if FileExists(GetUserDir + '.config/autostart/stickynotes.desktop') then
      AutoStartItem.Bitmap.Assign(bmp)
    else
      AutoStartItem.Bitmap.Clear;
  finally
    bmp.Free;
  end;
end;

end.
