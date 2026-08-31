--kreiranje baze
CREATE DATABASE prijavaIspita
GO
--kreiranje tabele predmet
CREATE TABLE predmet(
sifra int identity(1,1) primary key,
naziv nvarchar(30) not null,
semestar int not null CHECK (semestar in(1,2,3,4,5,6)), --semestri odgovaraju trogodisnjem studijskom programu 
status nvarchar(20) not null CHECK(status in(N'Obavezan',N'Izborni')),
espb int not null
)
GO
--kreiranje tabele student
CREATE TABLE student(
id int identity(1,1) primary key,
ime nvarchar(30) not null,
prezime nvarchar(30) not null,
jmbg char(13) not null UNIQUE,
smer nvarchar(10) not null CHECK(smer in(N'NRT', N'RT', N'IS', N'ASUV', N'AVT', N'ELITE', N'NET', N'ELIN',  N'MIN', N'RIN')),--smerovi na VISER-u
broj int not null,--redni broj indeksa
email nvarchar(30) not null UNIQUE,
godinaStudija int not null,
datumUpisa date not null DEFAULT GETDATE()
)
GO
--kreiranje pomocne tabele student_predmet
CREATE TABLE student_predmet(
idStudenta int,
idPredmeta int,
status nvarchar(30) not null CHECK(status in(N'Odslušao',N'Sluša',N'Preneo')),
akademskaGodIzbora nvarchar(7) not null,--cuva se u formatu 2025/26
constraint fk_student foreign key (idStudenta) references student(id),
constraint fk_predmet foreign key (idPredmeta) references predmet(sifra),
constraint pk_studentpredmet primary key (idStudenta, idPredmeta)
)
GO
--kreiranje tabele predavac
CREATE TABLE predavac(
id int identity(1,1) primary key,
ime nvarchar(30) not null,
prezime nvarchar(30) not null,
zvanje nvarchar(10) not null ,
email nvarchar(30) not null UNIQUE,
datumZaposlenja date not null DEFAULT GETDATE()
)
GO
--kreiranje pomocne tabele predmet_predavac
CREATE TABLE predmet_predavac(
idPredavaca int,
idPredmeta int,
akademskaGod nvarchar(7) not null,
constraint fk_predavac foreign key (idPredavaca) references predavac(id),
constraint fk_predmetpredavac foreign key (idPredmeta) references predmet(sifra),
constraint pk_predavacpredmet primary key (idPredavaca, idPredmeta)
)
GO
--kreiranje tabele rok
CREATE TABLE rok(
id int identity(1,1) primary key,
naziv nvarchar(30) not null,
tip nvarchar(30) not null CHECK(tip in(N'Zimski',N'Letnji',N'Jesenji',N'Vanredni'))
)
GO
--kreiranje tabele ispitni_rok
CREATE TABLE ispitni_rok(
id int identity(1,1) primary key,
idRoka int not null,
datumPocetka date not null,
datumKraja date not null,
status nvarchar(30) not null CHECK(status in(N'Aktivan',N'Nije aktivan')),
constraint fk_rok foreign key (idRoka) references rok(id)
)
GO
--kreiranje tabele sala koja cuva informacije o salama za ispite
CREATE TABLE sala(
id int identity(1,1) primary key,
broj int not null
)
GO
--kreiranje tabele ispiti
CREATE TABLE ispit(
id int identity(1,1) primary key,
idIspitnogRoka int not null,
idPredmeta int not null,
idSale int not null,
datum datetime not null,
constraint fk_ispitnogrok foreign key (idIspitnogRoka) references ispitni_rok(id),
constraint fk_predmetispit foreign key (idPredmeta) references predmet(sifra),
constraint fk_sale foreign key (idSale) references sala(id)
)
GO
--kreiranje tabele prijava_ispita
CREATE TABLE prijava_ispita(
idStudenta int,
idIspita int,
ocena int,
constraint ck_ocena CHECK(ocena >= 5 AND ocena <= 10),
constraint fk_studentprijava foreign key (idStudenta) references student(id),
constraint fk_ispita foreign key (idIspita) references ispit(id),
constraint pk_prijavaispita primary key (idStudenta, idIspita)
)
