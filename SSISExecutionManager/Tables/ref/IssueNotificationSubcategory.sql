CREATE TABLE [dbo].[IssueNotificationSubcategory] (
    [IssueNotificationSubcategoryId]          INT            IDENTITY (1, 1) NOT NULL,
    [IssueNotificationCategoryId]             INT            NULL,
    [IssueNotificationSubcategoryDescription] VARCHAR (255)  NULL,
    [EmailDistributionList]                   NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_IssueNotificationSubcategory] PRIMARY KEY CLUSTERED ([IssueNotificationSubcategoryId] ASC),
    CONSTRAINT [FK_IssueNotificationSubcategory_IssueNotificationCategory] FOREIGN KEY ([IssueNotificationCategoryId]) REFERENCES [dbo].[IssueNotificationCategory] ([IssueNotificationCategoryId])
);

