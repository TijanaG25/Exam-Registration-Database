# Exam Tracking System Database

A relational database project for managing and tracking the **exam registration process at a higher education institution**.

The system manages students, courses, lecturers, exam periods, exams, classrooms, exam registrations, and grades. The database implements business rules directly at the database level using **T-SQL, views, user-defined functions, stored procedures, DML triggers, transactions, constraints, and indexes**.

The project was developed using **Microsoft SQL Server** and **SQL Server Management Studio (SSMS)**.

## Project Overview

The main goal of the project is to provide a centralized and reliable database for managing the exam process.

The system supports three types of users:

* **Student** – attends courses, registers for exams, and receives grades.
* **Lecturer** – participates in course management and enters grades.
* **Administrator** – manages students, lecturers, courses, exam periods, exams, and classrooms.

The database enforces business rules automatically, reducing manual errors and ensuring data consistency and integrity.

## Main Features

* Student management
* Course management
* Lecturer management
* Student-course enrollment
* Lecturer-course assignment
* Exam period management
* Exam scheduling
* Classroom management
* Exam registration
* Grade entry
* Tracking passed exams
* Calculation of earned ECTS points
* Validation of exam registration requirements
* Prevention of duplicate exam registrations
* Prevention of registering exams for already passed courses
* Prevention of closing an exam period before all grades are entered
* Automatic removal of registrations when an exam is deleted
* Transaction management and error handling
* Query performance optimization using indexes
* Query analysis using SQL Server Execution Plans

## Database Structure

The database consists of the following main tables:

| Table              | Description                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------- |
| `student`          | Stores student information, including personal data, study program, index number, email, and year of study. |
| `predmet`          | Stores courses, semesters, course types, and ECTS points.                                                   |
| `student_predmet`  | Connects students with the courses they attend.                                                             |
| `predavac`         | Stores lecturer information.                                                                                |
| `predmet_predavac` | Connects lecturers with the courses they teach.                                                             |
| `rok`              | Stores exam period types.                                                                                   |
| `ispitni_rok`      | Stores specific exam periods, their dates, and status.                                                      |
| `sala`             | Stores classrooms used for exams.                                                                           |
| `ispit`            | Stores scheduled exams, including course, exam period, classroom, date, and time.                           |
| `prijava_ispita`   | Stores student exam registrations and grades.                                                               |

The database uses **primary keys, foreign keys, UNIQUE constraints, CHECK constraints, NOT NULL constraints, and default values** to maintain referential integrity and prevent invalid data.

## Database Relationships

The database is based on a relational model with several one-to-many and many-to-many relationships.

Examples include:

* A student can attend multiple courses.
* A course can be attended by multiple students.
* A lecturer can teach multiple courses.
* A course can have multiple lecturers.
* An exam period can contain multiple exams.
* A course can have multiple exams in different exam periods.
* A classroom can be used for multiple exams at different times.
* A student can register for multiple exams.

The many-to-many relationships are resolved using the associative tables `student_predmet`, `predmet_predavac`, and `prijava_ispita`.

## Views

The database contains views that simplify access to frequently required information.

### `vStudentiPredmeti`

Displays students together with the courses they attend and the lecturers teaching those courses. It also provides information about the student's course status, academic year of enrollment, semester, course type, and ECTS points.

### `vAktivniIspiti`

Provides information about exams belonging to active exam periods, including the exam date, course, course status, ECTS points, and exam period.

### `vPolozeniIspiti`

Displays information about students and the exams they have successfully passed.

## User-Defined Functions

The project implements different types of user-defined functions.

### `fn_ukupnoESPB`

Calculates the total number of ECTS points earned by a student based on passed exams. Only exams with a grade greater than 5 contribute to the total.

### `fn_IspitiUroku`

An inline table-valued function that returns all exams belonging to a specified exam period, including:

* Exam period dates
* Exam period status
* Exam date and time
* Classroom
* Course

### `fn_dostupni_ispiti`

A multi-statement table-valued function that returns the exams a particular student is currently eligible to register for.

The function checks whether:

* the student has completed the course,
* the exam period is active,
* the exam date is in the future,
* the student has not already registered for the exam,
* the student has not already passed the course.

## Triggers

DML triggers are used to automatically enforce important business rules at the database level.

### `tr_prijava_ispita`

An `INSTEAD OF INSERT` trigger that validates exam registration.

Before allowing a registration, it checks:

1. Whether the student has completed the course.
2. Whether the student has already passed the course.
3. Whether the exam belongs to an active exam period and has not started yet.

Only if all conditions are satisfied is the registration inserted into `prijava_ispita`.

### `tr_zatvaranje_roka`

An `AFTER UPDATE` trigger that prevents an exam period from being closed while there are still registered exams without entered grades.

If an attempt is made to close such an exam period, the operation is cancelled using `ROLLBACK TRANSACTION`.

### `tr_brisanje_ispita`

An `AFTER DELETE` trigger that automatically deletes all exam registrations associated with an exam when that exam is deleted.

This prevents registrations from referencing an exam that no longer exists.

## Stored Procedures

Stored procedures are used for operations that modify data and require multiple validation steps.

### `sp_unos_ocene`

Used for entering a grade for a registered exam.

The procedure validates the grade and the existing exam registration before modifying the database.

### `sp_prijava_ispita`

Used to register a student for an exam.

The procedure verifies that:

* the student exists,
* the exam exists,
* the student has not already registered for the exam.

After these checks, the registration is inserted with a `NULL` grade. The insert then activates `tr_prijava_ispita`, which performs additional business-rule validation.

### `sp_dodaj_ispit`

Used to schedule a new exam.

The procedure validates:

* the exam period exists and is active,
* the course exists,
* the classroom exists,
* the classroom is not already occupied at the selected time,
* an exam for the same course does not already exist in the selected exam period.

## Transactions and Error Handling

Stored procedures use **transactions** together with `TRY...CATCH` blocks.

If an error occurs during an operation:

* the transaction is rolled back,
* the database remains in a consistent state,
* the corresponding error message is displayed.

This approach provides reliable execution of operations involving multiple validation steps.

## Constraints and Data Integrity

The database uses several types of constraints to ensure valid and consistent data:

* **Primary Keys** – uniquely identify records.
* **Foreign Keys** – maintain relationships between tables.
* **UNIQUE constraints** – prevent duplicate values such as student JMBG and email addresses.
* **CHECK constraints** – restrict values to valid ranges or predefined options.
* **NOT NULL constraints** – ensure required information is provided.
* **DEFAULT constraints** – automatically assign default values such as registration and employment dates.

For example, grades are restricted to values from **5 to 10**, while course status, study programs, exam period types, and exam period statuses are restricted to predefined values.

## Indexes and Query Optimization

The project also includes database performance analysis and indexing.

A **clustered index** is automatically created for the primary key of the `ispit` table. SQL Server creates a clustered index for a primary key unless another index type is explicitly specified.

A **nonclustered index** is created on the `idStudenta` column of the `prijava_ispita` table:

```sql
CREATE NONCLUSTERED INDEX IX_prijava_student
ON prijava_ispita(idStudenta);
```

The index improves queries that frequently search exam registrations by student. The project also compares query execution before and after indexing using SQL Server Execution Plans.

## Test Data

The database includes test data for:

* Students
* Courses
* Lecturers
* Course enrollments
* Lecturer-course assignments
* Exam periods
* Classrooms
* Exams
* Exam registrations
* Grades

The test data was used to verify the functionality of views, functions, stored procedures, triggers, and indexes.

## Technologies

* **Microsoft SQL Server**
* **T-SQL**
* **SQL Server Management Studio 22**
* Relational Database Design
* DDL and DML
* Views
* User-Defined Functions
* Stored Procedures
* DML Triggers
* Transactions
* Error Handling
* Primary and Foreign Keys
* Database Constraints
* Clustered and Nonclustered Indexes
* SQL Server Execution Plans

The database was developed and tested using **SQL Server Management Studio 22**.

## How to Run

1. Install **Microsoft SQL Server**.
2. Install **SQL Server Management Studio (SSMS)**.
3. Open the `.sql` script in SSMS.
4. Execute the script to create the `prijavaIspita` database.
5. The script creates the database structure, relationships, and database objects.
6. Execute the provided test-data scripts to populate the database.
7. Run the example queries and procedure/function calls to test the system.

## Project Goals

The project focuses on:

* Designing a normalized relational database.
* Centralizing information related to the exam process.
* Maintaining data integrity and consistency.
* Implementing business rules at the database level.
* Automating validation using triggers and stored procedures.
* Using transactions for reliable data modifications.
* Improving query performance using indexes.
* Analyzing query execution using SQL Server Execution Plans.

The project demonstrates how a database can contain not only stored data, but also **business logic and validation mechanisms** required for a reliable information system.
