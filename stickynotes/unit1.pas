unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, Menus, FileUtil, Process;

type

  { TMainForm }

  TMainForm = class(TForm)
    ExitItem: TMenuItem;
    AboutItem: TMenuItem;
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
    procedure ImportItemClick(Sender: TObject);
    procedure NewNoteItemClick(Sender: TObject);
    procedure AutoStartItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ShowAllItemClick(Sender: TObject);
    procedure CloseAllItemClick(Sender: TObject);
    procedure ShowAllNotes;
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
  if FindFirst(GetUserDir + '.config/stickynotes/*', faAnyFile, SR) = 0 then
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
  if FindFirst(GetUserDir + '.config/stickynotes/*', faAnyFile, SR) = 0 then
    try
      repeat
        if SR.Attr and faDirectory = 0 then
        begin
          NoteForm := TNoteForm.Create(Self);
          NoteForm.Name := SR.Name;
          NoteForm.Show;
        end;
      until FindNext(SR) <> 0
    finally
      FindClose(SR);
    end;
end;

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
  if FileExists(GetUserDir + '.config/autostart/stickynotes.desktop') then
    AutoStartItem.Checked := True;
end;

//Показать все
procedure TMainForm.ShowAllItemClick(Sender: TObject);
var
  i: integer;
begin
  //Закрываем все заметки
  for i := Screen.FormCount - 1 downto 0 do
    if Pos('NoteForm', Screen.Forms[i].Name) <> 0 then
      Screen.Forms[i].Close;

  Application.ProcessMessages;   //тут не освобождалась форма!

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
  if SaveDialog1.Execute then
  begin
    //Закрываем все открытые записки
    CloseAllItem.Click;

    //Экспорт
    RunCommand('/bin/bash', ['-c', 'tar -czf "' + SaveDialog1.FileName +
      '" -C ~/.config/stickynotes .'], s);

    TrayIcon1.BalloonTitle := SExportTitle;
    TrayIcon1.BalloonHint := SExportMessage;
    TrayIcon1.ShowBalloonHint;
  end;
end;

procedure TMainForm.AboutItemClick(Sender: TObject);
begin
  AboutForm.Show;
end;

//Импорт записок StickyNotes.tar.gz
procedure TMainForm.ImportItemClick(Sender: TObject);
var
  s: ansistring;
begin
  if OpenDialog1.Execute then
  begin
    //Закрываем все открытые записки
    CloseAllItem.Click;

    //Импорт
    RunCommand('/bin/bash', ['-c', 'rm -f ~/.config/stickynotes/*; tar -xvf "' +
      OpenDialog1.FileName + '" -C ~/.config/stickynotes'], s);

    TrayIcon1.BalloonTitle := SImportTitle;
    TrayIcon1.BalloonHint := SImportMessage;
    TrayIcon1.ShowBalloonHint;
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
