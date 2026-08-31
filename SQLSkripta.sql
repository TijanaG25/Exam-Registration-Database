--kreiranje pogleda vStudentiPremdeti
--prikazuje studente i njihove izabrane predmete i profesore koji ih drzi
create view vStudentiPredmeti as
select concat(s.ime,' ',s.prezime,' ',concat(s.smer,'-',s.broj,'/',trim(str(year(s.datumUpisa)%100)))) as Student,
		sp.status as 'Status slusanja', sp.akademskaGodIzbora as 'Izabrao',
		p.naziv as Predmet,p.semestar as Semestar, p.status as Status, p.espb as ESPB,
		concat(pr.zvanje,' ',pr.ime,' ',pr.prezime) as Predavac
from student s join student_predmet sp on s.id=sp.idStudenta
				join predmet p on p.sifra=sp.idPredmeta
				join predmet_predavac pp on pp.idPredmeta=p.sifra
				join predavac pr on pr.id=pp.idPredavaca
GO
--poziv pogleda
select *
from vStudentiPredmeti
GO
--kreiranje pogleda vAktivni ispiti
--prikazuje sve aktivne ispite koji tek predstoje u svim ispitnim rokovima
create view vAktivniIspiti as
select convert(varchar(10),i.datum,104) as 'Datum ispita',p.sifra as Sifra, p.naziv as Predmet,p.status as Status,p.espb as ESPB,
		r.naziv as Rok
from ispit i join predmet p on i.idPredmeta=p.sifra
			join ispitni_rok ir on ir.id=i.idIspitnogRoka
			join rok r on r.id=ir.idRoka
where ir.status=N'Aktivan' and i.datum>GETDATE()
GO
--poziv pogleda
select *
from vAktivniIspiti
GO
--kreiranje pogleda vPolozeniIspiti
--prikazuje studente i njihove polozene ispite
CREATE VIEW vPolozeniIspiti as
select concat(s.ime,' ',s.prezime,' ',concat(s.smer,'-',s.broj,'/',trim(str(year(s.datumUpisa)%100)))) as Student,
		p.naziv as Predmet, convert(varchar(10),i.datum,104) as 'Datum polaganja', pri.ocena as Ocena
from student s join prijava_ispita pri on pri.idStudenta=s.id
				join ispit i on i.id=pri.idIspita
				join predmet p on p.sifra=i.idPredmeta
where pri.ocena is not null and pri.ocena>5
GO
--poziv pogleda
select *
from vPolozeniIspiti
GO
--kreiranje funkcije dbo.fn_ukupnoESPB
--funkcija vraca ukupan broj espb bodova za studenta ciji je id prosledjen
CREATE FUNCTION dbo.fn_ukupnoESPB
(@StudentID INT)
RETURNS int
AS
BEGIN
DECLARE @ukupno int =0
select @ukupno = sum(p.espb)
FROM predmet p join ispit i on i.idPredmeta=p.sifra
	join prijava_ispita pri on pri.idIspita=i.id
	join student s on s.id=pri.idStudenta
where s.id=@StudentID and pri.ocena>5
RETURN @ukupno
END
GO
--poziv funkcije
select ime,prezime,dbo.fn_ukupnoESPB(id) AS UkupnoESPB
from student
order by dbo.fn_ukupnoESPB(id) DESC
GO
--kreiranje funkcije dbo.fn_IspitiUroku
--funkcija ispisuje sve ispite koji su bili i ce biti u roku ciji je id prosledjen
CREATE FUNCTION dbo.fn_IspitiUroku
(@idRoka int)
RETURNS TABLE
AS
RETURN
(SELECT ir.datumPocetka as Pocetak, ir.datumKraja as Kraj, ir.status as Status,
		i.datum as 'Datum ispita', s.broj as 'Broj sale', p.naziv as Predmet
FROM rok r join ispitni_rok ir on ir.idRoka=r.id
			join ispit i on i.idIspitnogRoka=ir.id
			join predmet p on p.sifra=i.idPredmeta
			join sala s on s.id=i.idSale
WHERE r.id=@idRoka)
GO
--poziv funkcije
select * 
from dbo.fn_IspitiUroku(1)
GO
--kreiranje funkcije dbo.fn_dostupni_ispiti
--vraca ispite koje odredjeni student moze da prijavi
CREATE FUNCTION dbo.fn_dostupni_ispiti(@idStudenta int)
RETURNS @dostupni TABLE (IdIspita int,
    Predmet nvarchar(30),
    Datum varchar(10),
    Rok nvarchar(30),
    TipRoka nvarchar(30),
    Predavac nvarchar(50),
    Sala int
)
AS BEGIN
    INSERT INTO @dostupni
    SELECT i.id, p.naziv,convert(varchar(10),i.datum,104),r.naziv, r.tip,concat(prof.ime,' ',prof.prezime), sa.broj
    FROM ispit i
    JOIN predmet p ON i.idPredmeta = p.sifra
    JOIN ispitni_rok ir ON i.idIspitnogRoka = ir.id
    JOIN rok r ON ir.idRoka = r.id
    JOIN sala sa ON i.idSale = sa.id
    JOIN student_predmet sp ON sp.idPredmeta = p.sifra
    JOIN predmet_predavac pp on p.sifra=pp.idPredmeta
    JOIN predavac prof on prof.id=pp.idPredavaca
    WHERE sp.idStudenta = @idStudenta
    AND sp.status = N'Odslušao'
    AND ir.status = N'Aktivan'
    AND i.datum > GETDATE()
    AND i.id NOT IN (SELECT idIspita FROM prijava_ispita
                     WHERE idStudenta = @idStudenta)--proveravamo da li je student vec prijavio ispit
    AND p.sifra NOT IN (
        SELECT i2.idPredmeta
        FROM prijava_ispita pri
        JOIN ispit i2 ON pri.idIspita = i2.id
        WHERE pri.idStudenta = @idStudenta
        AND pri.ocena >= 6
    )--proveravamo da li je student polozio taj predmet
    RETURN
END
GO
--poziv funkcije
select *
from dbo.fn_dostupni_ispiti(11)
GO
--kreiranje instead of okidaca tr_prijava_ispita
--okidac prilikom prijave ispita proverava glavne uslove za polaganje odredjenog predmeta
CREATE TRIGGER tr_prijava_ispita
ON prijava_ispita
INSTEAD OF INSERT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM inserted ins
        JOIN ispit i ON ins.idIspita = i.id
        JOIN student_predmet sp ON sp.idPredmeta = i.idPredmeta
        WHERE sp.idStudenta = ins.idStudenta
        AND sp.status = N'Odslušao'
    )
    BEGIN
        RAISERROR(N'Student nije odslušao ovaj predmet.', 16, 1)
        RETURN
    END
    IF EXISTS (
        SELECT 1 FROM inserted ins
        JOIN ispit i ON ins.idIspita = i.id
        JOIN prijava_ispita pi ON pi.idStudenta = ins.idStudenta
        JOIN ispit i2 ON pi.idIspita = i2.id
        WHERE i2.idPredmeta = i.idPredmeta
        AND pi.ocena >= 6
    )
    BEGIN
        RAISERROR(N'Student je već položio ovaj predmet.', 16, 1)
        RETURN
    END
    IF NOT EXISTS (
        SELECT 1 FROM inserted ins
        JOIN ispit i ON ins.idIspita = i.id
        JOIN ispitni_rok ir ON i.idIspitnogRoka = ir.id
        WHERE ir.status = N'Aktivan'
        AND i.datum > GETDATE()
    )
    BEGIN
        RAISERROR(N'Ispit nije u aktivnom roku.', 16, 1)
        RETURN
    END
    INSERT INTO prijava_ispita (idStudenta, idIspita, ocena)
    SELECT idStudenta, idIspita, ocena FROM inserted
END
GO
--kreiranje after okidaca tr_zatvaranje_roka
--okidac proverava da li su sve ocene unete pre "zatvaranja" roka
CREATE TRIGGER tr_zatvaranje_roka
ON ispitni_rok
AFTER UPDATE
AS
BEGIN
    IF UPDATE(status)
    BEGIN
        IF EXISTS (
            SELECT 1 FROM inserted ins
            JOIN ispit i ON i.idIspitnogRoka = ins.id
            JOIN prijava_ispita pi ON pi.idIspita = i.id
            WHERE ins.status = N'Nije aktivan'
            AND pi.ocena IS NULL
        )
        BEGIN
            RAISERROR(N'Nisu sve ocene unesene. Rok ne može biti zatvoren.', 16, 1)
            ROLLBACK TRANSACTION
        END
    END
END
GO
--kreiranje after okidaca tr_brisanje_ispita
--prilikom brisanja ispita sve prijave za taj ispit se ponistavaju
CREATE TRIGGER tr_brisanje_ispita
ON ispit
AFTER DELETE
AS
BEGIN
    DELETE FROM prijava_ispita
    WHERE idIspita IN (SELECT id FROM deleted)
END
GO
--kreiranje procedure sa transakcijom sp_unos_ocene
--procedura unosi ocenu na odredjenom ispitu za odredjenog studenta
CREATE PROCEDURE sp_unos_ocene
    @idStudenta int,
    @idIspita int,
    @ocena int
AS
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        IF @ocena < 5 OR @ocena > 10
        BEGIN
            RAISERROR(N'Ocena mora biti između 5 i 10.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF NOT EXISTS (SELECT 1 FROM prijava_ispita 
                       WHERE idStudenta = @idStudenta 
                       AND idIspita = @idIspita)
        BEGIN
            RAISERROR(N'Student nije prijavljen za ovaj ispit.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF EXISTS (SELECT 1 FROM prijava_ispita 
                   WHERE idStudenta = @idStudenta 
                   AND idIspita = @idIspita
                   AND ocena IS NOT NULL)
        BEGIN
            RAISERROR(N'Ocena je već unesena i ne može biti izmenjena.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        UPDATE prijava_ispita
        SET ocena = @ocena
        WHERE idStudenta = @idStudenta 
        AND idIspita = @idIspita
        COMMIT TRANSACTION
        PRINT N'Ocena uspešno unesena.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE()
    END CATCH
END
GO
--poziv procedure
EXEC sp_unos_ocene 1,1,8
GO
--kreiranje porocedure sa transakcijom sp_prijava_ispita
--procedurom se prijavljuje ispit za odredjenog studenta, proveravaju se uslovi
--procedura pokrece okidac tr_prijava_ispita
--ako procedura i okidac ne prijave gresku -> transakcija je uspesna
CREATE PROCEDURE sp_prijava_ispita
    @idStudenta int,
    @idIspita int
AS
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM student 
                       WHERE id = @idStudenta)
        BEGIN
            RAISERROR(N'Student ne postoji.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF NOT EXISTS (SELECT 1 FROM ispit 
                       WHERE id = @idIspita)
        BEGIN
            RAISERROR(N'Ispit ne postoji.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF EXISTS (SELECT 1 FROM prijava_ispita 
                   WHERE idStudenta = @idStudenta 
                   AND idIspita = @idIspita)
        BEGIN
            RAISERROR(N'Student je već prijavljen za ovaj ispit.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        INSERT INTO prijava_ispita (idStudenta, idIspita, ocena)
        VALUES (@idStudenta, @idIspita, NULL)
        COMMIT TRANSACTION
        PRINT N'Ispit uspešno prijavljen.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE()
    END CATCH
END
GO
--poziv procedure
EXEC sp_prijava_ispita 1,4
GO
--kreiranje procedure sa transakcijom sp_dodaj_ispit
--kreiranje ispita za odredjeni predmet u odredjenom roku i sali 
CREATE PROCEDURE sp_dodaj_ispit
    @idIspitnogRoka int,
    @idPredmeta int,
    @idSale int,
    @datum datetime
AS
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM ispitni_rok 
                       WHERE id = @idIspitnogRoka
                       AND status = N'Aktivan')
        BEGIN
            RAISERROR(N'Ispitni rok ne postoji ili nije aktivan.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF NOT EXISTS (SELECT 1 FROM predmet 
                       WHERE sifra = @idPredmeta)
        BEGIN
            RAISERROR(N'Predmet ne postoji.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF NOT EXISTS (SELECT 1 FROM sala 
                       WHERE id = @idSale)
        BEGIN
            RAISERROR(N'Sala ne postoji.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF EXISTS (SELECT 1 FROM ispit 
                   WHERE idSale = @idSale 
                   AND datum = @datum)
        BEGIN
            RAISERROR(N'Sala je već zauzeta u tom terminu.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        IF EXISTS (SELECT 1 FROM ispit
                   WHERE idIspitnogRoka = @idIspitnogRoka
                   AND idPredmeta = @idPredmeta)
        BEGIN
            RAISERROR(N'Ispit iz tog predmeta već postoji u ovom roku.', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END
        INSERT INTO ispit (idIspitnogRoka, idPredmeta, idSale, datum)
        VALUES (@idIspitnogRoka, @idPredmeta, @idSale, @datum)
        COMMIT TRANSACTION
        PRINT N'Ispit uspešno dodat.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE()
    END CATCH
END
GO
--poziv procedure
EXEC sp_dodaj_ispit 3,1,1,'2026-08-15 09:00:00'
GO
--kreiranje neklasterovanog indeksa IX_prijava_student
create nonclustered index IX_prijava_student
on prijava_ispita(idStudenta)
GO
--kreiranje neklasterovanog indeksa IX_ispitni_rok
create nonclustered index IX_ispitni_rok
on ispitni_rok(status)
GO
