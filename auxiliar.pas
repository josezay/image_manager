unit Auxiliar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

procedure Inicializar();
procedure PDFDir();
procedure Executar();

implementation

uses Biblio, form_principal;

procedure Inicializar();
begin
    // Define os labels dos diretórios com os dados das configurações
    Principal.LabelPDFAuxiliar.Caption  := Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'];

    // Define a pasta inicial para os diálogos de diretório
    Principal.DirectoryPDFAuxiliar.InitialDir  := Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'];
end;

//********** Eventos Auxiliar **************************************************
// Ao clicar para escolha do destino do PDF do Auxiliar
procedure PDFDir();
begin
    if Principal.DirectoryPDFAuxiliar.Execute then
    begin
        Principal.LabelPDFAuxiliar.Caption := Principal.DirectoryPDFAuxiliar.Filename;
        Principal.DirectoryPDFAuxiliar.InitialDir := Principal.DirectoryPDFAuxiliar.Filename;
        Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'] := Principal.DirectoryPDFAuxiliar.Filename;
        Principal.FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup do Auxiliar
procedure Executar();
var
    Auxiliar: String;
    Erro: boolean;
begin
    Auxiliar := Principal.CampoNumeroAuxiliar.Text;
    Principal.BtnExecutarAuxiliar.Enabled  := false;
    Principal.ProgressBarAuxiliar.Visible  := true;
    Principal.ProgressBarAuxiliar.Position := 0;
    Erro := false;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.

    if valida(3) then
    begin
        Principal.ProgressBarAuxiliar.Position := 20;
        if (Principal.CheckBoxGerarPDFAuxiliar.Checked) then
        begin
            if not (geraPDF(Auxiliar, 3)) then
            begin
                ShowMessage('Ocorreu erro ao gerar PDF!');
                Erro := true;
            end;
        end;

        Principal.ProgressBarAuxiliar.Position := 70;
        Principal.Update;

        if (Principal.CheckBoxApagarImagensAuxiliar.Checked) then
        begin
            if not (apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        Principal.ProgressBarAuxiliar.Position := 100;
        Principal.Update;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    Principal.BtnExecutarAuxiliar.Enabled := true;
end;

end.

