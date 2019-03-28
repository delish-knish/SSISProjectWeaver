
CREATE VIEW [catalog].[catalog_properties]
AS
SELECT     [property_name], 
           [property_value]
FROM       [internal].[catalog_properties]
UNION
SELECT     [property_name], 
           [property_value]
FROM       [internal].[master_properties]
WHERE      [property_name] = 'IS_SCALEOUT_ENABLED'
