unit Biblio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DCPsha256;

  function sha256(S: String): String;

implementation

uses form_principal;

function sha256(S: String): String;
var
    Hash: TDCP_sha256;
    Digest: array[0..31] of byte;
    Source: string;
    i: integer;
    str1: string;
begin
    Source := S;

    if Source <> '' then
    begin
        Hash := TDCP_sha256.Create(nil);
        Hash.Init;
        Hash.UpdateStr(Source);
        Hash.Final(Digest);
        str1 := '';
        for i:= 0 to 31 do
            str1 := str1 + IntToHex(Digest[i],2);

        sha256 :=LowerCase(str1);
    end;
end;

end.

