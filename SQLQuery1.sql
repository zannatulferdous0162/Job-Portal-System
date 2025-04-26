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
-- "VIEW" WITH ENCRYPTION
--=============================================================================

CREATE VIEW job.EncryptedCandidatesView
WITH ENCRYPTION
AS
SELECT 
    CandidateID,
    FirstName,
    LastName,
    Email
FROM 
    job.Candidates;
GO



