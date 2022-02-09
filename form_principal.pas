unit form_principal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, IniPropStorage, Menus,
  DCPsha256, fphttpclient, FileUtil, form_config;

type

  { TPrincipal }

  TPrincipal = class(TForm)
    BarraDeStatus: TStatusBar;
    CampoNumeroMatricula: TEdit;
    CheckBoxApagarImagensAuxiliar: TCheckBox;
    CheckBoxBackupAuxiliar: TCheckBox;
    CheckBoxGerarPDFAuxiliar: TCheckBox;
    CheckBoxApagarImagensMatricula: TCheckBox;
    CheckBoxGerarRARMatricula: TCheckBox;
    CheckBoxEnviarNuvem: TCheckBox;
    CheckBoxGerarPDFMatricula: TCheckBox;
    CheckBoxGerarTIFMatricula: TCheckBox;
    ConfigStorage: TIniPropStorage;
    CampoNumeroAuxiliar: TEdit;
    DialogoImagens: TOpenDialog;
    FormStorage: TIniPropStorage;
    LabelNumeroAuxiliar: TLabel;
    LabelPDFMatricula: TLabel;
    LabelRARMatricula: TLabel;
    LabelTIFMatricula: TLabel;
    LabelListaArquivos: TLabel;
    LabelNumeroMatricula: TLabel;
    ListaArquivos: TListBox;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PainelImagens: TPanel;
    ProgressBarAuxiliar: TProgressBar;
    ProgressBarMatricula: TProgressBar;
    ScrollBox1: TScrollBox;
    MenuToolBar: TToolBar;
    ScrollBox2: TScrollBox;
    DirectoryPDFMatricula: TSelectDirectoryDialog;
    DirectoryRARMatricula: TSelectDirectoryDialog;
    DirectoryTIFMatricula: TSelectDirectoryDialog;
    BtnSair: TSpeedButton;
    BtnRARDirMatricula: TSpeedButton;
    BtnAbrirImagem: TSpeedButton;
    BtnPDFDirMatricula: TSpeedButton;
    BtnTIFDirMatricula: TSpeedButton;
    BtnExecutarMatricula: TSpeedButton;
    BtnConfig: TSpeedButton;
    BtnExecutarAuxiliar: TSpeedButton;
    BtnPDFDirAuxiliar: TSpeedButton;
    LabelPDFAuxiliar: TStaticText;
    DirectoryPDFAuxiliar: TSelectDirectoryDialog;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure BtnAbrirImagemClick(Sender: TObject);
    procedure BtnExecutarAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirMatriculaClick(Sender: TObject);
    procedure BtnTIFDirMatriculaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnExecutarMatriculaClick(Sender: TObject);
    procedure BtnSairClick(Sender: TObject);
    procedure BtnRARDirMatriculaClick(Sender: TObject);
    procedure BtnConfigClick(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    function valida(Tipo: integer): boolean;
    function geraRAR(Matricula: string): boolean;
    function geraTIF(Matricula: string): boolean;
    function geraPDF(Numero: string; Tipo: integer): boolean;
    function sincronizaArquivo(Numero: string; Tipo: integer): boolean;
    function apagaArquivosOrigem(): boolean;
  private

  public

  end;

var
  Principal: TPrincipal;
  Imagens: array of String;                                                     // Lista de arquivos, pode ser populada pelo diálogo de abertura de imagens, ou arrastando as imagens sobre o programa.

implementation

uses Biblio;

{$R *.lfm}

{ TPrincipal }

//********** Eventos gerais ****************************************************

// Ao iniciar
procedure TPrincipal.FormCreate(Sender: TObject);
begin
    // Carrega as configurações para o programa
    FormStorage.IniFileName   := 'config.ini';
    ConfigStorage.IniFileName := 'config.ini';
    FormStorage.Restore;
    ConfigStorage.Restore;

    // Define os labels dos diretórios com os dados das configurações
    LabelRARMatricula.Caption := FormStorage.StoredValue['DiretorioRARMatricula'];
    LabelPDFMatricula.Caption := FormStorage.StoredValue['DiretorioPDFMatricula'];
    LabelTIFMatricula.Caption := FormStorage.StoredValue['DiretorioTIFMatricula'];
    LabelPDFAuxiliar.Caption  := FormStorage.StoredValue['DiretorioPDFAuxiliar'];

    // Define a pasta inicial para os diálogos de diretório
    DirectoryRARMatricula.InitialDir := FormStorage.StoredValue['DiretorioRARMatricula'];
    DirectoryPDFMatricula.InitialDir := FormStorage.StoredValue['DiretorioPDFMatricula'];
    DirectoryTIFMatricula.InitialDir := FormStorage.StoredValue['DiretorioTIFMatricula'];
    DirectoryPDFAuxiliar.InitialDir  := FormStorage.StoredValue['DiretorioPDFAuxiliar'];
end;

// Ao clicar para sair
procedure TPrincipal.BtnSairClick(Sender: TObject);
begin
    if QuestionDlg ('Sair','Deseja sair?',mtCustom,[mrYes,'Sim', mrNo, 'Não'],'') = mrYes then
        Close;
end;

// Ao clicar para configurar
procedure TPrincipal.BtnConfigClick(Sender: TObject);
begin
    Config.ShowModal;                                                           // Chama a tela de configuração.
end;

procedure TPrincipal.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
  I: Integer;
begin
    ListaArquivos.Items.Clear;                                                  // A lista é somente para exibir quais arquivos estão abertos, no formato simples, para melhor visualização.
    SetLength(Imagens, Length(FileNames));                                      // Define o tamanho da array que irá comportar os nomes completos dos arquivos e de onde as conversões irão consultar.
    for I := Low(FileNames) to High(FileNames) do                               // Do primeiro ao último arquivo no drag and drop.
    begin
        if ((ExtractFileExt(FileNames[I]) = '.jpg') Or (ExtractFileExt(FileNames[I]) = '.png') Or (ExtractFileExt(FileNames[I]) = '.bmp')) then
        begin
            Imagens[I] := FileNames[I];                                         // Popula a array de imagens.
            ListaArquivos.items.add(ExtractFileName(FileNames[I]));             // Mostra o nome do arquivo simples, sem o diretório, para fins de visualização somente.
        end;
    end;

    ProgressBarMatricula.Visible := false;                                      // Ao escolher novas imagens esconde as barras de progresso.
    ProgressBarAuxiliar.Visible  := false;
end;

// Ao clicar para abrir imagem
procedure TPrincipal.BtnAbrirImagemClick(Sender: TObject);
var
    I: integer;
begin
    if DialogoImagens.Execute then                                              // Chama a janela para escolher os arquivos.
    begin
        ListaArquivos.Items.Clear;                                              // Limpa a lista visual.
        SetLength(Imagens, DialogoImagens.Files.Count);                         // Define a array de imagens com tamanho que comporte a quantidade de arquivos escolhidos.
        for I := 0 to DialogoImagens.Files.Count - 1 do                         // Para cada arquivo escolhido.
        begin
            Imagens[I] := DialogoImagens.Files[I];                              // Insere o nome e diretório do arquivo no array de imagens
            ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I]));  // Mostra em tela o nome simples.
        end;

        ProgressBarMatricula.Visible := false;                                  // Ao escolher novas imagens esconde as barras de progresso.
        ProgressBarAuxiliar.Visible  := false;
    end;
end;

//********** Eventos Matricula *************************************************

// Ao clicar para escolha do destino do RAR da Matrícula
procedure TPrincipal.BtnRARDirMatriculaClick(Sender: TObject);
begin
    if DirectoryRARMatricula.Execute then
    begin
        LabelRARMatricula.Caption := DirectoryRARMatricula.Filename;
        DirectoryRARMatricula.InitialDir := DirectoryRARMatricula.Filename;
        FormStorage.StoredValue['DiretorioRARMatricula'] := DirectoryRARMatricula.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para escolha do destino do PDF da Matrícula
procedure TPrincipal.BtnPDFDirMatriculaClick(Sender: TObject);
begin
    if DirectoryPDFMatricula.Execute then
    begin
        LabelPDFMatricula.Caption := DirectoryPDFMatricula.Filename;
        DirectoryPDFMatricula.InitialDir := DirectoryPDFMatricula.Filename;
        FormStorage.StoredValue['DiretorioPDFMatricula'] := DirectoryPDFMatricula.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para escolha do destino do TIF da Matrícula
procedure TPrincipal.BtnTIFDirMatriculaClick(Sender: TObject);
begin
    if DirectoryTIFMatricula.Execute then
    begin
        LabelTIFMatricula.Caption := DirectoryTIFMatricula.Filename;
        DirectoryTIFMatricula.InitialDir := DirectoryTIFMatricula.Filename;
        FormStorage.StoredValue['DiretorioTIFMatricula'] := DirectoryTIFMatricula.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup da matrícula
procedure TPrincipal.BtnExecutarMatriculaClick(Sender: TObject);
var
    Matricula: String;
    Erro: boolean;
begin
    Matricula := CampoNumeroMatricula.Text;
    BtnExecutarMatricula.Enabled  := false;                                     // Desabilita o botão.
    ProgressBarMatricula.Visible  := true;                                      // Deixa visível a barra de progresso.
    ProgressBarMatricula.Position := 0;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.
    Erro := false;

    if valida(2) then
    begin
        ProgressBarMatricula.Position := 10;
        if (CheckBoxGerarRARMatricula.Checked) then
        begin
            if not (geraRAR(Matricula)) then
            begin
                ShowMessage('Ocorreu erro ao formar RAR!');
                Erro := true;
            end;
        end;

        ProgressBarMatricula.Position := 30;
        Principal.Update;

        if (CheckBoxGerarPDFMatricula.Checked) then
        begin
            if not (geraPDF(Matricula, 2)) then
            begin
                ShowMessage('Ocorreu erro ao formar PDF!');
                Erro := true;
            end;
        end;

        ProgressBarMatricula.Position := 40;
        Principal.Update;

        if (CheckBoxGerarTIFMatricula.Checked) then
        begin
            if not (geraTIF(Matricula)) then
            begin
                ShowMessage('Ocorreu erro ao formar TIF!');
                Erro := true;
            end;
        end;

        ProgressBarMatricula.Position := 90;
        Principal.Update;

        if (CheckBoxApagarImagensMatricula.Checked) then
        begin
            if not (apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        ProgressBarMatricula.Position := 100;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    BtnExecutarMatricula.Enabled:=true;
end;

//********** Eventos Auxiliar **************************************************
// Ao clicar para escolha do destino do PDF do Auxiliar
procedure TPrincipal.BtnPDFDirAuxiliarClick(Sender: TObject);
begin
    if DirectoryPDFAuxiliar.Execute then
    begin
        LabelPDFAuxiliar.Caption := DirectoryPDFAuxiliar.Filename;
        DirectoryPDFAuxiliar.InitialDir := DirectoryPDFAuxiliar.Filename;
        FormStorage.StoredValue['DiretorioPDFAuxiliar'] := DirectoryPDFAuxiliar.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup do Auxiliar
procedure TPrincipal.BtnExecutarAuxiliarClick(Sender: TObject);
var
    Auxiliar: String;
    Erro: boolean;
begin
    Auxiliar := CampoNumeroAuxiliar.Text;
    BtnExecutarAuxiliar.Enabled  := false;
    ProgressBarAuxiliar.Visible  := true;
    ProgressBarAuxiliar.Position := 0;
    Erro := false;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.

    if valida(3) then
    begin
        ProgressBarAuxiliar.Position := 20;
        if (CheckBoxGerarPDFAuxiliar.Checked) then
        begin
            if not (geraPDF(Auxiliar, 3)) then
            begin
                ShowMessage('Ocorreu erro ao gerar PDF!');
                Erro := true;
            end;
        end;

        ProgressBarAuxiliar.Position := 70;
        Principal.Update;

        if (CheckBoxApagarImagensAuxiliar.Checked) then
        begin
            if not (apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        ProgressBarAuxiliar.Position := 100;
        Principal.Update;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    BtnExecutarAuxiliar.Enabled := true;
end;

//********** Regra Negocial ****************************************************

// Validações
// Tipo : 2 se matrícula, 3 se auxiliar
function TPrincipal.valida(Tipo: integer): boolean;
var
    I: integer;
begin
    // Validações gerais;
    valida := true;
    if (Length(Imagens) = 0) then                                               // Se não ouverem imagens carregadas.
    begin
        MessageDlg('É necessário escolher ao menos uma imagem!', mtError, mbOKCancel, 0);
        if DialogoImagens.Execute then                                          // Se arquivos foram escolhidos.
        begin
            ListaArquivos.Items.Clear;                                          // Limpa na tela a lista.
            SetLength(Imagens, DialogoImagens.Files.Count);                     // Define o tamanho da array de imagens para que comporte as imagens escolhidas.
            for I := 0 to DialogoImagens.Files.Count - 1 do                     // Para cada arquivo escolhido.
            begin
                Imagens[I] := DialogoImagens.Files[I];                          // Adicina o arquivo na lista para ser processado.
                ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I])); // Mostra o nome simples na tela.
            end;
            valida := false;
            Exit;
        end;
    end;

    // Validações específicas
    if (Tipo = 2) then
    begin
        if (CampoNumeroMatricula.Text = '') then
        begin
            MessageDlg('Preencha o número da matrícula!', mtError, [mbOK], 0);
            CampoNumeroMatricula.SetFocus;
            valida := false;
            Exit;
        end;

        if (FormStorage.StoredValue['DiretorioRARMatricula'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos RAR!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;

        if (FormStorage.StoredValue['DiretorioPDFMatricula'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;

        if (FormStorage.StoredValue['DiretorioTIFMatricula'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos TIF!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;
    end
    else
    begin
        if (Tipo = 3) then
        begin
            if (CampoNumeroAuxiliar.Text = '') then
            begin
                MessageDlg('Preencha o número do Registro Auxiliar!', mtError, [mbOK], 0);
                CampoNumeroAuxiliar.SetFocus;
                valida := false;
                Exit;
            end;

            if (FormStorage.StoredValue['DiretorioPDFAuxiliar'] = '') then
            begin
                MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!', mtError, [mbOK], 0);
                valida := false;
                Exit;
            end;
        end;
    end;
end;

// Compacta arquivos
// Somente tipo 2 gera RAR
function TPrincipal.geraRAR(Matricula: string): boolean;
var
    RunProgram: TProcess;
    I: integer;
begin
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'bin/rar.exe';
    RunProgram.Parameters.Add('a');                                             // Compactar
    RunProgram.Parameters.Add('-ep1');                                          // Sem manter estrutura de arquivos
    RunProgram.Parameters.Add('"' + FormStorage.StoredValue['DiretorioRARMatricula'] + '/' + Matricula + '.rar"');

    for I := Low(Imagens) to High(Imagens) do
    begin
        RunProgram.Parameters.Add(Imagens[I]);
    end;

    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;

    if (RunProgram.ExitCode = 0) then geraRAR:=true                             // Se ouve erro ao executar processo externo.
    else geraRAR:=false;

    RunProgram.Free;
end;

// Gera PDF-A
// Numero: Nome do PDF
// Tipo: 2 se matrícula, 3 se auxiliar
function TPrincipal.geraPDF(Numero: string; Tipo: integer): boolean;
var
    RunProgram: TProcess;
    I: integer;
begin
    // Gera PDF normal temporário
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'magick';

    for I := Low(Imagens) to High(Imagens) do
    begin
        RunProgram.Parameters.Add(Imagens[I]);
    end;

    RunProgram.Parameters.Add(Numero + '.pdf');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;
    RunProgram.Free;

    // Gera PDFA
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'bin\gswin32c.exe';
    RunProgram.Parameters.Add('-dPDFA=1');
    RunProgram.Parameters.Add('-dNOSAFER');
    RunProgram.Parameters.Add('-dBATCH');
    RunProgram.Parameters.Add('-dNOPAUSE');
    RunProgram.Parameters.Add('-sDEVICE=pdfwrite');
    RunProgram.Parameters.Add('-sProcessColorModel=DeviceRGB');
    RunProgram.Parameters.Add('-sColorConversionStrategy=RGB');
    RunProgram.Parameters.Add('-dDOPDFMARKS=false');
    RunProgram.Parameters.Add('-dCompatibilityLevel=1.7');
    RunProgram.Parameters.Add('-dPDFACompatibilityPolicy=2');

    if (Tipo = 2) then
    begin
        RunProgram.Parameters.Add('-sOutputFile=' + '"' + FormStorage.StoredValue['DiretorioPDFMatricula'] + '\' + Numero + '.pdf"');
    end;

    if (Tipo = 3) then
    begin
        RunProgram.Parameters.Add('-sOutputFile=' + '"' + FormStorage.StoredValue['DiretorioPDFAuxiliar'] + '\' + Numero + '.pdf"');
    end;

    RunProgram.Parameters.Add('bin\PDFA_def.ps');
    RunProgram.Parameters.Add(Numero + '.pdf');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;

    if (RunProgram.ExitCode = 0) then geraPDF:=true                             // Se ouve erro ao executar processo externo.
    else geraPDF:=false;

    RunProgram.Free;

    sincronizaArquivo(Numero, Tipo);                                            // Sincroniza arquivo PDF-A com servidor

    if (FileExists(Numero + '.pdf')) then
    begin
        DeleteFile(Numero + '.pdf')                                             // Deleta PDF normal temporário.
    end;
end;

// Sincroniza um arquivo para o servidor
function TPrincipal.sincronizaArquivo(Numero: string; Tipo: integer): boolean;
var
    Respo: TStringStream;
    S, Arquivo: string;
begin
    if (Tipo = 2) then
    begin
        Arquivo := StringReplace(FormStorage.StoredValue['DiretorioPDFMatricula'], '\', '/', [rfReplaceAll]) + '/' + Numero + '.pdf';
    end;

    if (Tipo = 3) then
    begin
        Arquivo := StringReplace(FormStorage.StoredValue['DiretorioPDFAuxiliar'], '\', '/', [rfReplaceAll]) + '/' + Numero + '.pdf';
    end;

    With TFPHttpClient.Create(Nil) do
    try
        try
            Respo := TStringStream.Create('');
            FileFormPost(ConfigStorage.StoredValue['DiretorioRemoto'] + 'notaire_image.php?token=' + Biblio.sha256(Numero + '.pdf' + ConfigStorage.StoredValue['Senha']) + '&tipo=' + IntToStr(Tipo),
                         'file',
                         Arquivo,
                         Respo);
            S := Respo.DataString;
            Respo.Destroy;
        except
            BarraDeStatus.SimpleText := 'Sem conexão com a internet';
        end;
    finally
        if (S = '1') then                                                       // Se sucesso.
        begin
            BarraDeStatus.SimpleText := '';
            sincronizaArquivo := true;                                          // Sincroniza o arquivo PDF-A original.
        end
        else
        begin
            if (Tipo = 2) then
            begin
                CreateDir(ConfigStorage.StoredValue['DiretorioPendencias'] + '/matriculas/');
                CopyFile(Arquivo, ConfigStorage.StoredValue['DiretorioPendencias'] + '/matriculas/' + Numero + '.pdf');   // Copia o arquivo original na pasta pendentes.
            end;

            if (Tipo = 3) then
            begin
                CreateDir(ConfigStorage.StoredValue['DiretorioPendencias'] + '/auxiliares/');
                CopyFile(Arquivo, ConfigStorage.StoredValue['DiretorioPendencias'] + '/auxiliares/' + Numero + '.pdf');
            end;

            sincronizaArquivo := false;
        end;
    end;
end;

// Ressincroniza arquivos pendentes
//function TPrincipal.ressincronizaArquivos(): boolean;
//var
//    ArquivosPendentes: TStringList;
//    I: integer;
//begin
//    ArquivosPendentes := TStringList.Create;
//    try
//        if (ConfigStorage.StoredValue['Ressincroniza'] = 'true') then
//        begin
//            FindAllFiles(ArquivosPendentes, 'matriculas_pendentes', '*.pdf', true);
//            if (ArquivosPendentes.Count > 0) then
//            begin
//                ShowMessage(Format('Encontradas %d matricula(s) não sincronizada(s)', [ArquivosPendentes.Count]));
//                for I := 0 to ArquivosPendentes.Count - 1 do
//                begin
//                     sincronizaArquivo(ArquivosPendentes[I], 2);
//                end;
//            end;
//
//            FindAllFiles(ArquivosPendentes, 'auxiliares_pendentes', '*.pdf', true);
//            if (ArquivosPendentes.Count > 0) then
//            begin
//                ShowMessage(Format('Encontrados %d registros auxiliar(es) não sincronizado(s)', [ArquivosPendentes.Count]));
//                for I := 0 to ArquivosPendentes.Count - 1 do
//                begin
//                     sincronizaArquivo(ArquivosPendentes[I], 3);
//                end;
//            end;
//        end;
//    finally
//        ressincronizaArquivos := true;
//    end;
//end;

// Gera TIF
function TPrincipal.geraTIF(Matricula: string): boolean;
var
    I: integer;
    SubdiretorioTIF, NomeTIF: string;
    RunProgram: TProcess;
begin
    // Gera diretório
    SubdiretorioTIF := '00000000';                                              // Caso não entre no if abaixo
    if (Matricula.Length > 3) then
    begin
        SubdiretorioTIF := '';
        for I := 1 to Matricula.Length - 3 do
        begin
            SubdiretorioTIF := SubdiretorioTIF + Matricula[I];
        end;

        NomeTif := '';                                                          // Usa o nometif como temporário somente
        for I := SubdiretorioTIF.Length to 7 do
        begin
            NomeTIF := NomeTIF + '0';
        end;

        SubdiretorioTIF := NomeTIF + SubdiretorioTIF;
    end;

    if not DirectoryExists(FormStorage.StoredValue['DiretorioTIFMatricula'] + '/' + SubdiretorioTIF) then
    begin
        if not CreateDir(FormStorage.StoredValue['DiretorioTIFMatricula'] + '/' + SubdiretorioTIF) then
        begin
            MessageDlg('Falha ao criar subdiretório Tif, crie manualmente uma pasta de nome ' + SubdiretorioTIF + ' dentro de ' + FormStorage.StoredValue['DiretorioTIF'], mtError, mbOKCancel, 0);
            geraTIF := false;
        end;
    end;

    // Gera nome com 0MenuItemSair à esquerda
    NomeTIF := '';

    for I := Matricula.Length to 7 do
    begin
         NomeTIF := NomeTIF + '0';
    end;

    NomeTIF := NomeTIF + Matricula;

    // Converte para TIF
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'magick';

    for I := Low(Imagens) to High(Imagens) do
    begin
        RunProgram.Parameters.Add(Imagens[I]);
    end;

    if (ConfigStorage.StoredValue['ComprimirTIF'] = 'true') then                // Comprime o tif (preto e branco) se marcado para tal na configuração.
    begin
        RunProgram.Parameters.Add('-compress');
        RunProgram.Parameters.Add('group4');
    end;

    RunProgram.Parameters.Add('"' + FormStorage.StoredValue['DiretorioTIFMatricula'] + '/' + SubdiretorioTIF + '/' + NomeTIF + '.tif');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;

    if (RunProgram.ExitCode = 0) then geraTIF:=true                             // Se ouve erro ao executar processo externo.
    else geraTIF:=false;

    RunProgram.Free;
end;

// Apaga arquivos de origem
function TPrincipal.apagaArquivosOrigem(): boolean;
var
    I: integer;
begin
    for I := Low(Imagens) to High(Imagens) do
    begin
        if (FileExists(Imagens[I])) then
        begin
            DeleteFile(Imagens[I])
        end;
    end;

    ListaArquivos.Clear;
    SetLength(Imagens, 0);
    apagaArquivosOrigem := true;
end;

end.
