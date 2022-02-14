unit ConsultaNuvemLocal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, Dialogs;

procedure Conferir();

implementation

uses form_principal;

procedure Conferir();
var
    Respo: TStringStream;
    ArrArquivos, ArrRegistro, ArrTipo: TStringArray;
    S: string;
    I: integer;
begin
    Principal.MySQL.Open;
    Principal.SQLTransaction.StartTransaction;

    //S := TFPCustomHTTPClient.SimpleGet('http://homologador.compuniao.com.br/notaire/varredura_arquivos.php');
    S := Principal.SynServidor.Text;
    //S := '  ';
    ArrTipo := S.Split('&');
    //S := '1014.pdf#2014-02-13#216439|';
    //ArrArquivos:= SplitString(S, '|');
    ArrArquivos := ArrTipo[0].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.Memo.Append(ArrArquivos[I]);
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''2'', ''2'')', Principal.SQLTransaction);
        end;
    end;

    ArrArquivos := ArrTipo[1].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.Memo.Append(ArrArquivos[I]);
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''2'', ''3'')', Principal.SQLTransaction);
        end;
    end;

    S := TFPCustomHTTPClient.SimpleGet('http://192.168.1.102/varredura_arquivos.php');
    //S := '1014.pdf#2014-02-13#216439|';
    //ArrArquivos:= SplitString(S, '|');
    ArrTipo := S.Split('&');

    // Matriculas do cartorio.
    ArrArquivos := ArrTipo[0].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.Memo.Append(ArrArquivos[I]);
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''1'', ''2'')', Principal.SQLTransaction); //origem 1 = local
        end;
    end;

    // Auxiliares do cartorio.
    ArrArquivos := ArrTipo[1].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.Memo.Append(ArrArquivos[I]);
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''1'', ''3'')', Principal.SQLTransaction);
        end;
    end;

    Principal.SQLTransaction.Commit;                                            // Grava as inserções dos registros



    Principal.SQLTransaction.EndTransaction;
    Principal.MySQL.Close(false);
//ShowMessage(S);
end;

end.

