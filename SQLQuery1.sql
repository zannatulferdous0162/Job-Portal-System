--===============================================--
--         CREATING DATABASE FOR 'JOB PORTAL SYSTEM'
--===============================================--

USE master
GO

-- যদি JobPortalDB আগে থাকে, তাহলে ড্রপ করো
IF DB_ID('JobPortalDB') IS NOT NULL
    DROP DATABASE JobPortalDB
GO

-- ডেটা ফাইলের পাথ বের করা
USE master
GO
DECLARE @data_path NVARCHAR(256) 
SET @data_path = (
    SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
    FROM master.sys.master_files
    WHERE database_id = 1 AND file_id = 1
);

-- ডাটাবেস তৈরি করা
EXECUTE (
    'CREATE DATABASE JobPortalDB
        ON PRIMARY (
            NAME = JobPortalDB,
            FILENAME = ''' + @data_path + 'JobPortalDB.mdf'',
            SIZE = 100MB,
            MAXSIZE = UNLIMITED,
            FILEGROWTH = 5MB
        )
        LOG ON (
            NAME = JobPortalDB_log,
            FILENAME = ''' + @data_path + 'JobPortalDB_log.ldf'',
            SIZE = 30MB,
            MAXSIZE = 50MB,
            FILEGROWTH = 2MB
        )'
);
GO




--===============================================--
--          CREATING "SCHEMA" FOR JOB PORTAL SYSTEM
--===============================================--

USE JobPortalDB
GO




-- =============================================
-- Schema: job
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'job')
BEGIN
    EXEC('CREATE SCHEMA job');
END
GO

-- =============================================
-- Table: job.Companies
-- =============================================
CREATE TABLE job.Companies (
    CompanyID INT IDENTITY(1,1) NOT NULL,
    CompanyName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    ContactNumber NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Companies PRIMARY KEY (CompanyID),
    CONSTRAINT UQ_Companies_Email UNIQUE (Email)
);
GO

-- =============================================
-- Table: job.JobCategories
-- =============================================
CREATE TABLE job.JobCategories (
    JobCategoryID INT IDENTITY(1,1) NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_JobCategories PRIMARY KEY (JobCategoryID),
    CONSTRAINT UQ_JobCategories_CategoryName UNIQUE (CategoryName)
);
GO

-- =============================================
-- Table: job.Candidates
-- =============================================
CREATE TABLE job.Candidates (
    CandidateID INT IDENTITY(1,1) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(15) NOT NULL,
    ResumeLink NVARCHAR(255) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    DateOfBirth DATE NOT NULL,
    RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Candidates PRIMARY KEY (CandidateID),
    CONSTRAINT UQ_Candidates_Email UNIQUE (Email)
);
GO

-- =============================================
-- Table: job.SkillSets
-- =============================================
CREATE TABLE job.SkillSets (
    SkillSetID INT IDENTITY(1,1) NOT NULL,
    SkillName NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_SkillSets PRIMARY KEY (SkillSetID),
    CONSTRAINT UQ_SkillSets_SkillName UNIQUE (SkillName)
);
GO

-- =============================================
-- Table: job.JobPosts
-- =============================================
CREATE TABLE job.JobPosts (
    JobPostID INT IDENTITY(1,1) NOT NULL,
    CompanyID INT NOT NULL,
    JobCategoryID INT NOT NULL,
    Position NVARCHAR(100) NOT NULL,
    Salary DECIMAL(18,2) NOT NULL CHECK (Salary >= 0),
    JobDescription NVARCHAR(MAX) NOT NULL,
    Location NVARCHAR(100) NOT NULL,
    PostedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ExpiryDate DATE NOT NULL,
    CONSTRAINT PK_JobPosts PRIMARY KEY (JobPostID),
    CONSTRAINT FK_JobPosts_Companies FOREIGN KEY (CompanyID) REFERENCES job.Companies(CompanyID),
    CONSTRAINT FK_JobPosts_Categories FOREIGN KEY (JobCategoryID) REFERENCES job.JobCategories(JobCategoryID)
);
GO

-- =============================================
-- Table: job.Recruiters
-- =============================================
CREATE TABLE job.Recruiters (
    RecruiterID INT IDENTITY(1,1) NOT NULL,
    CompanyID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(15) NOT NULL,
    CONSTRAINT PK_Recruiters PRIMARY KEY (RecruiterID),
    CONSTRAINT UQ_Recruiters_Email UNIQUE (Email),
    CONSTRAINT FK_Recruiters_Companies FOREIGN KEY (CompanyID) REFERENCES job.Companies(CompanyID)
);
GO

-- =============================================
-- Table: job.Applications
-- =============================================
CREATE TABLE job.Applications (
    ApplicationID INT IDENTITY(1,1) NOT NULL,
    JobPostID INT NOT NULL,
    CandidateID INT NOT NULL,
    ApplicationDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT PK_Applications PRIMARY KEY (ApplicationID),
    CONSTRAINT FK_Applications_JobPosts FOREIGN KEY (JobPostID) REFERENCES job.JobPosts(JobPostID),
    CONSTRAINT FK_Applications_Candidates FOREIGN KEY (CandidateID) REFERENCES job.Candidates(CandidateID),
    CONSTRAINT CHK_Applications_Status CHECK (Status IN ('Pending', 'Approved', 'Rejected'))
);
GO

-- =============================================
-- Table: job.InterviewSchedules
-- =============================================
CREATE TABLE job.InterviewSchedules (
    InterviewID INT IDENTITY(1,1) NOT NULL,
    ApplicationID INT NOT NULL,
    InterviewDate DATE NOT NULL,
    InterviewTime TIME NOT NULL,
    InterviewMode NVARCHAR(20) NOT NULL,
    InterviewerName NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_InterviewSchedules PRIMARY KEY (InterviewID),
    CONSTRAINT FK_InterviewSchedules_Applications FOREIGN KEY (ApplicationID) REFERENCES job.Applications(ApplicationID),
    CONSTRAINT CHK_InterviewSchedules_Mode CHECK (InterviewMode IN ('In-Person', 'Phone', 'Video'))
);
GO

-- =============================================
-- Table: job.OfferLetters
-- =============================================
CREATE TABLE job.OfferLetters (
    OfferLetterID INT IDENTITY(1,1) NOT NULL,
    ApplicationID INT NOT NULL,
    OfferedSalary DECIMAL(18,2) NOT NULL CHECK (OfferedSalary >= 0),
    JoiningDate DATE NOT NULL,
    OfferStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT PK_OfferLetters PRIMARY KEY (OfferLetterID),
    CONSTRAINT FK_OfferLetters_Applications FOREIGN KEY (ApplicationID) REFERENCES job.Applications(ApplicationID),
    CONSTRAINT CHK_OfferLetters_Status CHECK (OfferStatus IN ('Pending', 'Accepted', 'Declined'))
);
GO

-- =============================================
-- Table: job.CandidateSkills
-- =============================================
CREATE TABLE job.CandidateSkills (
    CandidateSkillID INT IDENTITY(1,1) NOT NULL,
    CandidateID INT NOT NULL,
    SkillSetID INT NOT NULL,
    CONSTRAINT PK_CandidateSkills PRIMARY KEY (CandidateSkillID),
    CONSTRAINT FK_CandidateSkills_Candidates FOREIGN KEY (CandidateID) REFERENCES job.Candidates(CandidateID),
    CONSTRAINT FK_CandidateSkills_SkillSets FOREIGN KEY (SkillSetID) REFERENCES job.SkillSets(SkillSetID),
    CONSTRAINT UQ_CandidateSkills UNIQUE (CandidateID, SkillSetID)
);
GO
-- =============================================
-- Table: job.Users
-- =============================================


CREATE TABLE job.Users (
    UserID INT IDENTITY(1,1) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(15) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL, -- Store hashed passwords
    UserRole NVARCHAR(20) NOT NULL, -- e.g., Admin, Candidate, Recruiter
    Status NVARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT PK_Users PRIMARY KEY (UserID),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);
GO


-- =============================================
-- Table: job.JobApplicationHistory
-- =============================================

CREATE TABLE job.JobApplicationHistory (
    HistoryID INT IDENTITY(1,1) NOT NULL,
    ApplicationID INT NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    StatusDate DATETIME NOT NULL DEFAULT GETDATE(),
    Remarks NVARCHAR(MAX),
    CONSTRAINT PK_JobApplicationHistory PRIMARY KEY (HistoryID),
    CONSTRAINT FK_JobApplicationHistory_Applications FOREIGN KEY (ApplicationID) REFERENCES job.Applications(ApplicationID),
    CONSTRAINT CHK_JobApplicationHistory_Status CHECK (Status IN ('Applied', 'Interviewed', 'Offered', 'Rejected'))
);
GO

CREATE TABLE job.Overtime
(
    OvertimeID INT IDENTITY(1,1) PRIMARY KEY,
    CandidateID INT NOT NULL,
    DateWorked DATE NOT NULL,
    HoursWorked INT NOT NULL,
    Overtime BIT NOT NULL DEFAULT 1,
    
    -- Optional: CandidateID কে foreign key করো যদি তোমার job.Candidates বা job.Applications table থাকে
    -- FOREIGN KEY (CandidateID) REFERENCES job.Candidates(CandidateID)
);


-----========================================================================
                             -- ALTER TABLE
-----========================================================================


ALTER TABLE job.Companies
ADD Website NVARCHAR(255) NULL;



ALTER TABLE job.Candidates
ALTER COLUMN PhoneNumber NVARCHAR(20) NOT NULL;



ALTER TABLE job.JobPosts
ADD JobType NVARCHAR(50) NULL;



ALTER TABLE job.Applications
ADD StatusDate DATETIME NULL;




ALTER TABLE job.Users
DROP COLUMN Phone;



ALTER TABLE job.OfferLetters
ADD BonusAmount DECIMAL(18, 2) NULL;



ALTER TABLE job.InterviewSchedules
ADD InterviewDurationMinutes INT NULL;

--ALTER TABLE job.Overtime
--ADD 
--    DateWorked DATE NULL,
--    CandidateID INT NULL,
--    Overtime BIT NULL,
--    HoursWorked INT NULL;



--=========================================================================================
                -- CREATING "INDEX" CLUSTURED + NON CLUSTERED
--===========================================================================================
-- CLUSTERED INDEX: ApplicationID + ApplicationDate এর উপর
CREATE UNIQUE CLUSTERED INDEX IX_Clustered_Applications
ON job.Applications (ApplicationID, ApplicationDate);
GO

-- NON-CLUSTERED INDEX: Status + StatusDate এর উপর
CREATE NONCLUSTERED INDEX IX_NonClustered_Applications_Status
ON job.Applications (Status, StatusDate);
GO

--=============================================================================
-- "-- Create the view with schema binding and encryption

--=============================================================================


USE JobPortalDB;
GO

CREATE VIEW job.vw_CandidateJobApplications
WITH SCHEMABINDING, ENCRYPTION
AS
SELECT 
    a.ApplicationID,
    a.ApplicationDate,
    a.Status,
    c.FirstName AS CandidateFirstName,
    c.LastName AS CandidateLastName,
    jp.Position AS JobPosition,
    jp.Location AS JobLocation,
    comp.CompanyName AS CompanyName
FROM 
    job.Applications AS a
INNER JOIN 
    job.Candidates AS c ON a.CandidateID = c.CandidateID
INNER JOIN 
    job.JobPosts AS jp ON a.JobPostID = jp.JobPostID
INNER JOIN
    job.Companies AS comp ON jp.CompanyID = comp.CompanyID;
GO

--=============================================================================
-- "-- -- Create a view with encryption

--=============================================================================

CREATE VIEW job.EncryptedJobApplicationsView
WITH ENCRYPTION
AS
SELECT 
    a.ApplicationID,
    c.FirstName AS CandidateFirstName,
    c.LastName AS CandidateLastName,
    j.Position AS JobPosition,
    a.Status AS ApplicationStatus
FROM 
    job.Applications AS a
JOIN 
    job.Candidates AS c ON a.CandidateID = c.CandidateID
JOIN 
    job.JobPosts AS j ON a.JobPostID = j.JobPostID;
GO


---===================================================================================================
							 -- CREATING A "TABULAR FUNCTION"
--==================================================================================================

-- Create an Inline Table-Valued Function (ITVF)
CREATE FUNCTION job.GetJobApplicationsByCandidate
(
    @CandidateID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        a.ApplicationID,
        a.ApplicationDate,
        j.Position AS JobPosition,
        a.Status
    FROM 
        job.Applications AS a
    JOIN 
        job.JobPosts AS j ON a.JobPostID = j.JobPostID
    WHERE 
        a.CandidateID = @CandidateID
);
GO


--SELECT * 
--FROM job.GetJobApplicationsByCandidate(1);
---===================================================================================================
							 ----CREATING "SCALAR FUNCTION" FOR CALCULATION 
--==================================================================================================


-- Create a scalar function to calculate the total applications by a candidate
CREATE FUNCTION job.fn_GetTotalApplicationsByCandidate
(
    @CandidateID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @TotalApplications INT;

    -- Calculate the total number of applications submitted by the candidate
    SELECT @TotalApplications = COUNT(*) 
    FROM job.Applications
    WHERE CandidateID = @CandidateID;

    -- Return the result
    RETURN @TotalApplications;
END;
GO

--SELECT job.fn_GetTotalApplicationsByCandidate(1) AS TotalApplications;


--SELECT c.CandidateID, c.FirstName, c.LastName, 
--       job.fn_GetTotalApplicationsByCandidate(c.CandidateID) AS TotalApplications
--FROM job.Candidates c;


-- Create a scalar function to calculate the total salary offer for a candidate

CREATE FUNCTION job.fn_CalculateTotalSalaryOffer
(
    @CandidateID INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @BaseSalary DECIMAL(18, 2);
    DECLARE @TotalSalaryOffer DECIMAL(18, 2);

    -- Get the Base Salary from the JobPost based on the Candidate's Application
    SELECT @BaseSalary = j.Salary
    FROM job.JobPosts j
    JOIN job.Applications a ON j.JobPostID = a.JobPostID
    WHERE a.CandidateID = @CandidateID AND a.Status = 'Pending'; -- Assuming the application is still 'Pending'

    -- Calculate Total Salary Offer (Base Salary in this case)
    SET @TotalSalaryOffer = ISNULL(@BaseSalary, 0);  -- Default to 0 if no salary is found

    -- Return the Total Salary Offer
    RETURN @TotalSalaryOffer;
END;
GO




/******* OVERTIME FUNCTION ****/
CREATE FUNCTION job.fn_CalculateOvertimeAmount
(
    @EmployeeID INT,
    @PayPeriodStart DATE,
    @PayPeriodEnd DATE
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @HourlyRate DECIMAL(10, 2);
    DECLARE @OvertimeHours INT;
    DECLARE @OvertimeMultiplier DECIMAL(10, 2);
    DECLARE @OvertimeAmount DECIMAL(10, 2);

    -- Hourly rate calculation
    SELECT @HourlyRate = j.Salary / 160
    FROM job.JobPosts j
    JOIN job.Applications a ON j.JobPostID = a.JobPostID
    WHERE a.CandidateID = @EmployeeID;

    -- Overtime hours calculation
    SELECT @OvertimeHours = ISNULL(SUM(o.HoursWorked), 0)
    FROM job.Overtime o
    WHERE o.CandidateID = @EmployeeID
    AND o.DateWorked BETWEEN @PayPeriodStart AND @PayPeriodEnd;

    -- Overtime multiplier
    SET @OvertimeMultiplier = 1.5;

    -- Overtime amount calculation
    SET @OvertimeAmount = @HourlyRate * @OvertimeHours * @OvertimeMultiplier;

    RETURN @OvertimeAmount;
END;
GO


USE JobPortalDB
GO

CREATE PROCEDURE job.Employee_Insert
    @EmployeeName NVARCHAR(100),
    @Position NVARCHAR(100),
    @JoiningDate DATE,
    @Salary DECIMAL(18, 2),
    @BonusAmount DECIMAL(18, 2) = NULL
AS
BEGIN
    INSERT INTO job.Employees (EmployeeName, Position, JoiningDate, Salary, BonusAmount)
    VALUES (@EmployeeName, @Position, @JoiningDate, @Salary, @BonusAmount);
END


--update


CREATE PROCEDURE job.Employee_Update
    @EmployeeId INT,
    @EmployeeName NVARCHAR(100),
    @Position NVARCHAR(100),
    @JoiningDate DATE,
    @Salary DECIMAL(18, 2),
    @BonusAmount DECIMAL(18, 2) = NULL
AS
BEGIN
    UPDATE job.Employees
    SET 
        EmployeeName = @EmployeeName,
        Position = @Position,
        JoiningDate = @JoiningDate,
        Salary = @Salary,
        BonusAmount = @BonusAmount
    WHERE EmployeeId = @EmployeeId;
END

--Delete
CREATE PROCEDURE job.Employee_Delete
    @EmployeeId INT
AS
BEGIN
    DELETE FROM job.Employees
    WHERE EmployeeId = @EmployeeId;
END




--=====================================================================================
			--STORE PROCEDURE FOR MULTIPLE TABLE(INCLUDING TEMPORARY TABLE)
--======================================================================================

-- Create a stored procedure for multiple tables
CREATE PROCEDURE job.GetJobApplicationsByCompany
    @CompanyID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary Table to Store Final Result
    CREATE TABLE #JobApplicationDetails
    (
        ApplicationID INT,
        ApplicantName NVARCHAR(100),
        ApplicantEmail NVARCHAR(100),
        JobTitle NVARCHAR(150),
        CompanyName NVARCHAR(150),
        ApplyDate DATE,
        ApplicationStatus NVARCHAR(50)
    );

    -- Insert Data into Temporary Table
    INSERT INTO #JobApplicationDetails (ApplicationID, ApplicantName, ApplicantEmail, JobTitle, CompanyName, ApplyDate, ApplicationStatus)
    SELECT 
        a.ApplicationID,
        ap.FullName AS ApplicantName,
        ap.Email AS ApplicantEmail,
        jp.JobTitle,
        c.CompanyName,
        a.ApplyDate,
        a.ApplicationStatus
    FROM 
        job.Applications a
    INNER JOIN 
        job.Applicants ap ON a.ApplicantID = ap.ApplicantID
    INNER JOIN 
        job.JobPosts jp ON a.JobPostID = jp.JobPostID
    INNER JOIN 
        job.Companies c ON jp.CompanyID = c.CompanyID
    WHERE 
        c.CompanyID = @CompanyID;

    -- Select Final Result
    SELECT * FROM #JobApplicationDetails;

    -- Drop the Temporary Table
    DROP TABLE #JobApplicationDetails;
END;
GO


--========================================================--===============================================
				            --  "AFTER TRIGGERS" FOR INSERT, UPDATE, AND DELETE
--========================================================================================================

-- Create an Audit Table for Application Changes
CREATE TABLE job.ApplicationAuditLog
(
    AuditLogID INT PRIMARY KEY IDENTITY(1,1),
    Operation NVARCHAR(10) NOT NULL,    -- INSERT, UPDATE, DELETE
    ApplicationID INT,
    ApplicantID INT,
    JobPostID INT,
    ApplyDate DATE,
    ApplicationStatus NVARCHAR(50),
    AuditDateTime DATETIME DEFAULT GETDATE()
);
GO



-- AFTER INSERT Trigger
CREATE TRIGGER job.trg_AfterInsert_Application
ON job.Applications
AFTER INSERT
AS
BEGIN
    INSERT INTO job.ApplicationAuditLog (Operation, ApplicationID,JobPostID)
    SELECT 
        'INSERT',
        i.ApplicationID,
       
        i.JobPostID
            
    FROM inserted i;
END;
GO

-- AFTER UPDATE Trigger
CREATE TRIGGER job.trg_AfterUpdate_Application
ON job.Applications
AFTER UPDATE
AS
BEGIN
    INSERT INTO job.ApplicationAuditLog (Operation, ApplicationID, JobPostID)
    SELECT 
        'UPDATE',
        i.ApplicationID,
      
        i.JobPostID

       
    FROM inserted i;
END;
GO


-- AFTER DELETE Trigger
CREATE TRIGGER job.trg_AfterDelete_Application
ON job.Applications
AFTER DELETE
AS
BEGIN
    INSERT INTO job.ApplicationAuditLog (Operation, ApplicationID, JobPostID)
    SELECT 
        'DELETE',
        d.ApplicationID,
       
        d.JobPostID

    FROM deleted d;
END;
GO
