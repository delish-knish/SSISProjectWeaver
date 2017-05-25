SSIS Project Weaver

Welcome to the SSIS Project Weaver repository. Here you will find everything you need to either 1) extend the highly-extensible SSIS Project Weaver T-SQL-based SSIS execution framework or 2) deploy the framework and begin using it to execute your SQL Server Integration Services 2012, 2014, and/or 2016 projects. 

Overview
SSIS Project Weaver framework is primarily implemented via the SSISExecutionManager database which is a SQL Server database that is built on top of the logging and execution mechanisms contained within the out-of-the-box MS SQL Server SSISDB database. It uses a completely T-SQL based approach to controlling the execution of SSIS packages via user-configurable dependencies between packages, groups of packages, and custom SQL-based triggers/commands. Unlike SSIS Project Deployment model, the framework allows for cross-project package dependencies and execeution. Additional features include extensive logging and reporting that go beyond what is available in SSIS, SSISDB, and SSMS, configurable auto-retry on failure, restartability without the headaches that come with checkpoint files, exception handling and notification and more. All of this is available without having to make a single change to your existing projects and packages. Please see the wiki *Home* page for additional highlights.

What Next?
To get started we recommend that you review and install the *Prerequisites* as defined in the wiki and then continue by following the *Getting Started* page. 
