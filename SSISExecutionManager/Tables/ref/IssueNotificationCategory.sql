CREATE TABLE [dbo].[IssueNotificationCategory] (
    [IssueNotificationCategoryId]          INT           IDENTITY (1, 1) NOT NULL,
    [IssueNotificationCategoryDescription] VARCHAR (255) NULL,
    CONSTRAINT [PK_IssueNotificationCategory] PRIMARY KEY CLUSTERED ([IssueNotificationCategoryId] ASC)
);

