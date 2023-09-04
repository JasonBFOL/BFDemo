unit CNTMainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Buttons, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.FileCtrl,
  Vcl.Grids, System.IOUtils, System.Generics.Defaults,
  System.Generics.Collections;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Grid1: TStringGrid;
    StatusBar1: TStatusBar;
    Panel2: TPanel;
    SearchBtn: TButton;
    FileNameFilterEdt: TLabeledEdit;
    DirEdt: TLabeledEdit;
    SelectDirBtn: TSpeedButton;
    TongPeiFuEdt: TLabeledEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    DigitalFromEdt: TLabeledEdit;
    DigitalToEdt: TLabeledEdit;
    DigitalOccupyEdt: TLabeledEdit;
    ChangeRuleEdt: TLabeledEdit;
    Memo1: TMemo;
    GroupBox3: TGroupBox;
    ReadyBtn: TButton;
    ExecuteBtn: TButton;
    Splitter1: TSplitter;
    SearchTextEdt: TLabeledEdit;
    ReplaceTextEdt: TLabeledEdit;
    procedure SelectDirBtnClick(Sender: TObject);
    procedure SearchBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ReadyBtnClick(Sender: TObject);
    procedure ExecuteBtnClick(Sender: TObject);
  private
    { Private declarations }
    procedure FillGridHeader;
    function NewFileName(pattern: string; TongPeiFu: string; idx: integer;
      DigitalOccupy: integer): string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.ExecuteBtnClick(Sender: TObject);
var
  I: integer;
  baseDir: String;
begin
  (Sender as TButton).Enabled := false;
  try
    baseDir := DirEdt.Text + '\';
    for I := 1 to Grid1.RowCount - 1 do
    begin
      if RenameFile(baseDir + Grid1.Cells[0, I], baseDir + Grid1.Cells[1, I])
      then
        Grid1.Cells[3, I] := 'OK'
      else
        Grid1.Cells[3, I] := 'Fail';
    end;
  finally
    (Sender as TButton).Enabled := true;
  end;
end;

procedure TForm1.FillGridHeader;
var
  I, J: integer;
begin
  for I := 0 to Grid1.col - 1 do
    for J := 0 to Grid1.RowCount - 1 do
      Grid1.Cells[I, J] := '';

  Grid1.ColCount := 4;
  Grid1.RowCount := 2;
  Grid1.Cells[0, 0] := '文件名';
  Grid1.Cells[1, 0] := '修改后文件名';
  Grid1.Cells[2, 0] := '文件日期';
  Grid1.Cells[3, 0] := '状态';

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FillGridHeader;

{$IFDEF DEBUG}
  FileNameFilterEdt.Text := '*.d7d';
  DirEdt.Text := 'C:\测试-1';
  ChangeRuleEdt.Text := 'Data_*.d7d';
{$ENDIF}
end;

function TForm1.NewFileName(pattern, TongPeiFu: string;
  idx, DigitalOccupy: integer): string;
var
  vStr: string;
  tmpStr: string;
begin
  vStr := format('%' + DigitalOccupy.toString + 'u', [idx]);
  vStr := vStr.Replace(' ', '0');

  tmpStr := pattern.Replace(TongPeiFu, vStr);
  result := tmpStr;
end;

procedure TForm1.ReadyBtnClick(Sender: TObject);
var
  I, idx, IdxFrom, IdxTo, DigitalOccupy: integer;
begin
  (Sender as TButton).Enabled := false;
  try
    for I := 1 to Grid1.RowCount do
    begin
      Grid1.Cells[1, I] := Grid1.Cells[0, I];
    end;

    // 如果有通配符,则按照通配符规则生成数字并替换
    if Trim(TongPeiFuEdt.Text) <> '' then
    begin
      IdxFrom := StrToInt(DigitalFromEdt.Text);
      idx := IdxFrom;
      IdxTo := StrToInt(DigitalToEdt.Text);
      DigitalOccupy := StrToInt(DigitalOccupyEdt.Text);

      for I := 1 to Grid1.RowCount do
      begin
        Grid1.Cells[1, I] := NewFileName(ChangeRuleEdt.Text, TongPeiFuEdt.Text,
          idx, DigitalOccupy);
        idx := idx + 1;
      end;
    end;

    // 如果有需要搜索并替换的文本,则替换
    SearchTextEdt.Text := Trim(SearchTextEdt.Text);
    ReplaceTextEdt.Text := Trim(ReplaceTextEdt.Text);
    if Trim(SearchTextEdt.Text) <> '' then
    begin
      for I := 1 to Grid1.RowCount do
      begin
        Grid1.Cells[1, I] := Grid1.Cells[1, I].Replace(SearchTextEdt.Text,
          ReplaceTextEdt.Text);
      end;
    end;
  finally
    (Sender as TButton).Enabled := true;
  end;
end;

procedure TForm1.SearchBtnClick(Sender: TObject);
type
  FileInfoRecord = packed record
    FileName: string;
    DT: TDateTime;
  end;
var
  FileList: TSTringList;
  FileInfoList: array of FileInfoRecord;
  Comparer: IComparer<FileInfoRecord>;
  I: integer;
begin
  (Sender as TButton).Enabled := false;
  try
    FillGridHeader;

    Comparer := TDelegatedComparer<FileInfoRecord>.Create(
      function(const Left, Right: FileInfoRecord): integer
      var
        v: real;
      begin
        v := Left.DT - Right.DT;
        if v > 0 then
          result := 1
        else if v < 0 then
          result := -1
        else
          result := 0;
      end);

    FileList := TSTringList.Create;
    FileList.AddStrings(TDirectory.GetFiles(DirEdt.Text,
      FileNameFilterEdt.Text));

    Grid1.RowCount := FileList.Count + 1;

    SetLength(FileInfoList, FileList.Count);

    for I := 0 to FileList.Count - 1 do
    begin
      FileInfoList[I].FileName := FileList[I];
      FileInfoList[I].DT := TFile.GetLastWriteTime(FileList[I]);
    end;

    TArray.Sort<FileInfoRecord>(FileInfoList, Comparer);

    for I := LOW(FileInfoList) to High(FileInfoList) do
    begin
      Grid1.Cells[0, I + 1] := TPath.GetFileName(FileInfoList[I].FileName);
      Grid1.Cells[1, I + 1] := '';
      Grid1.Cells[2, I + 1] := DateTimeToStr(FileInfoList[I].DT);
      Grid1.Cells[3, I + 1] := '';
    end;

  finally
    (Sender as TButton).Enabled := true;
  end;
end;

procedure TForm1.SelectDirBtnClick(Sender: TObject);
var
  DirStr: string;
begin
  if SelectDirectory(DirStr, [], 0) then
  begin
    DirEdt.Text := DirStr;
  end;
end;

end.
