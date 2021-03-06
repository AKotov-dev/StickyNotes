unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, Menus, IniPropStorage, FileUtil, Process;

type

  { TMainForm }

  TMainForm = class(TForm)
    ExitItem: TMenuItem;
    AboutItem: TMenuItem;
    FontDialog1: TFontDialog;
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
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ShowAllItemClick(Sender: TObject);
    procedure CloseAllItemClick(Sender: TObject);
    procedure ShowAllNotes;
    procedure TransparencyItemClick(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);

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

//Показать все заметки по конфигам
procedure TMainForm.ShowAllNotes;
var
  SR: TSearchRec;
begin
  if FindFirst(GetUserDir + '.config/stickynotes/NoteForm*', faAnyFile, SR) = 0 then
    try
      repeat
        if SR.Attr and faDirectory = 0 then
        begin
          NoteForm := TNoteForm.Create(Self);
          NoteForm.Name := SR.Name;
          //+Прозрачность от MainForm
          NoteForm.AlphaBlend := MainForm.AlphaBlend;
          NoteForm.Font := MainForm.Font;
          NoteForm.Font.Color := clBlack;
          NoteForm.Show;
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
begin
  if TransparencyItem.Checked then
    TransparencyItem.Checked := False
  else
    TransparencyItem.Checked := True;

  MainForm.AlphaBlend := TransparencyItem.Checked;
  IniPropStorage1.Save;

  for i := 0 to Screen.FormCount - 1 do
    if Pos('NoteForm', Screen.Forms[i].Name) <> 0 then
      Screen.Forms[i].AlphaBlend := MainForm.AlphaBlend;
end;

//Показать/Скрыть все
procedure TMainForm.TrayIcon1DblClick(Sender: TObject);
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
  Close;
end;

procedure TMainForm.PopupMenu1Popup(Sender: TObject);
begin
  //Контроль автостарта
  if FileExists(GetUserDir + '.config/autostart/stickynotes.desktop') then
    AutoStartItem.Checked := True;

  //+Прозрачность
  TransparencyItem.Checked := MainForm.AlphaBlend;
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
begin
  TrayIcon1.Hint := Application.Title;
  TrayIcon1.Icon := Application.Icon;

  if not DirectoryExists(GetUserDir + '.config') then
    MkDir(GetUserDir + '.config');

  if not DirectoryExists(GetUserDir + '.config/stickynotes') then
    MkDir(GetUserDir + '.config/stickynotes');

  IniPropStorage1.IniFileName := GetUserDir + '.config/stickynotes/settings.conf';
  //Вытаскиваем Default-настройки
  IniPropStorage1.Restore;

  //+Прозрачность
  TransparencyItem.Checked := MainForm.AlphaBlend;

  //Сразу показываем заметки
  ShowAllItem.Click;
end;

//Добавить новую записку
procedure TMainForm.NewNoteItemClick(Sender: TObject);
var
  i: integer;
begin
  //Первая записка существует?
  if not FileExists(GetUserDir + '.config/stickynotes/NoteForm') then
  begin
    NoteForm := TNoteForm.Create(Self);
    //+Прозрачность
    NoteForm.AlphaBlend := MainForm.AlphaBlend;
    NoteForm.Font := MainForm.Font;
    NoteForm.Font.Color := clBlack;
    NoteForm.Show;
    Exit;
  end;

  for i := 1 to GetFilesCount do
  begin
    if not FileExists(GetUserDir + '.config/stickynotes/NoteForm' +
      '_' + IntToStr(i)) then
    begin
      NoteForm := TNoteForm.Create(Self);
      NoteForm.Name := 'NoteForm_' + IntToStr(i);
      //+Прозрачность
      NoteForm.AlphaBlend := MainForm.AlphaBlend;
      NoteForm.Font := MainForm.Font;
      NoteForm.Font.Color := clBlack;
      NoteForm.Show;
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

procedure TMainForm.FontItemClick(Sender: TObject);
var
  i: integer;
begin
  FontDialog1.Font := MainForm.Font;
  if FontDialog1.Execute then
  begin
    MainForm.Font := FontDialog1.Font;

    for i := 0 to Screen.FormCount - 1 do
      if Pos('NoteForm', Screen.Forms[i].Name) <> 0 then
      begin
        Screen.Forms[i].Font := MainForm.Font;
        Screen.Forms[i].Font.Color := clBlack;
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
begin
  if AutoStartItem.Checked then
    DeleteFile(GetUserDir + '.config/autostart/stickynotes.desktop')
  else
  begin
    if not DirectoryExists(GetUserDir + '.config/autostart') then
      MkDir(GetUserDir + '.config/autostart');

    CopyFile('/usr/share/stickynotes/stickynotes.desktop', GetUserDir +
      '.config/autostart/stickynotes.desktop', False);
  end;

  if FileExists(GetUserDir + '.config/autostart/stickynotes.desktop') then
    AutoStartItem.Checked := True
  else
    AutoStartItem.Checked := False;
end;


end.
