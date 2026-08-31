# Exam-Registration-Database

A relational database project for managing **students, courses, lecturers, exam periods, exams, classrooms, exam registrations, and grades**.

The database is developed using **Microsoft SQL Server** and demonstrates the use of relational database concepts, constraints, views, functions, triggers, stored procedures, transactions, and indexes.

## Features

The database supports the following functionalities:

* Student management
* Course management
* Lecturer management
* Student-course enrollment
* Lecturer-course assignments
* Exam period management
* Exam scheduling
* Classroom management
* Exam registration
* Grade management
* Validation of exam registration requirements
* Calculation of earned ECTS points
* Display of passed exams
* Display of available exams
* Automatic data validation using triggers
* Transaction management using stored procedures
* Database indexing for improved query performance

## Database Structure

The database contains the following main tables:

* **student** – stores student information such as name, surname, JMBG, study program, index number, email, and year of study.
* **predmet** – stores course information, including semester, course type, and ECTS points.
* **student_predmet** – connects students with the courses they attend.
* **predavac** – stores lecturer information.
* **predmet_predavac** – connects lecturers with the courses they teach.
* **rok** – stores exam period types.
* **ispitni_rok** – stores specific exam periods, their dates, and status.
* **sala** – stores classrooms used for exams.
* **ispit** – stores scheduled exams.
* **prijava_ispita** – stores student exam registrations and grades.

The database uses **primary keys, foreign keys, unique constraints, check constraints, and default values** to maintain data integrity.

## Views

The project contains several database views for retrieving commonly needed information:

### `vStudentiPredmeti`

Displays students, their selected courses, course information, and the lecturers teaching those courses.

### `vAktivniIspiti`

Displays upcoming exams that belong to currently active exam periods.

### `vPolozeniIspiti`

Displays students and the exams they have successfully passed.

## Functions

The database contains the following functions:

### `fn_ukupnoESPB`

Calculates the total number of ECTS points earned by a student based on successfully passed exams.

### `fn_IspitiUroku`

Returns all exams belonging to a specified exam period, including the exam date, classroom, course, and period status.

### `fn_dostupni_ispiti`

Returns the exams that a particular student is eligible to register for. The function checks whether:

* the student has completed the course,
* the exam period is active,
* the exam has not already started,
* the student has not already registered for the exam,
* the student has not previously passed the course.

## Triggers

The project uses triggers to enforce important business rules automatically.

### `tr_prijava_ispita`

An `INSTEAD OF INSERT` trigger that validates the main requirements for registering an exam, including whether the student has completed the course, whether the course has already been passed, and whether the exam belongs to an active exam period.

### `tr_zatvaranje_roka`

An `AFTER UPDATE` trigger that prevents an exam period from being closed if there are still registrations without entered grades.

### `tr_brisanje_ispita`

An `AFTER DELETE` trigger that automatically removes exam registrations associated with a deleted exam.

## Stored Procedures

The database contains stored procedures for performing important operations with transaction handling and validation.

### `sp_unos_ocene`

Enters a grade for a student's exam registration.

The procedure validates:

* grade range from 5 to 10,
* whether the student is registered for the exam,
* whether a grade has already been entered.

The operation is performed within a transaction.

### `sp_prijava_ispita`

Registers a student for an exam.

The procedure checks whether:

* the student exists,
* the exam exists,
* the student has not already registered for the exam.

The registration then activates the `tr_prijava_ispita` trigger, which performs additional eligibility checks.

### `sp_dodaj_ispit`

Creates an exam for a specific course, exam period, and classroom.

The procedure checks whether:

* the exam period exists and is active,
* the course exists,
* the classroom exists,
* the classroom is not already occupied at the specified time,
* an exam for the same course does not already exist in the selected exam period.

## Transactions and Error Handling

Stored procedures use **transactions** together with `TRY...CATCH` blocks to ensure that database operations are completed safely.

If a validation fails or an error occurs, the transaction is rolled back and the corresponding error message is displayed.

## Indexes

The project also demonstrates the use of **nonclustered indexes**:

* `IX_prijava_student` – created on `prijava_ispita(idStudenta)`
* `IX_ispitni_rok` – created on `ispitni_rok(status)`

These indexes are intended to improve the performance of queries frequently filtering or searching by these columns.

## Technologies

* **Microsoft SQL Server**
* **T-SQL**
* Relational Database Design
* Views
* User-Defined Functions
* Triggers
* Stored Procedures
* Transactions
* Indexes
* Primary and Foreign Keys
* Data Integrity Constraints

## Project Purpose

The project was developed as a practical exercise in **relational database design and T-SQL programming**.

It demonstrates how database-level logic can be used to enforce business rules, validate data, automate related operations, and provide reusable database functionality.

## Database Creation

To create the database, execute the SQL script in **SQL Server Management Studio (SSMS)**.

The script creates the database, tables, relationships, views, functions, triggers, stored procedures, and indexes required for the exam registration system.

## Author

Developed as an academic database project.
