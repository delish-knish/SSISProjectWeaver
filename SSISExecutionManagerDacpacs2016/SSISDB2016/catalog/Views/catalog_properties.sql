
CREATE VIEW [catalog].[catalog_properties]
AS
SELECT     [property_name], 
           [property_value]
FROM       [internal].[catalog_properties]
