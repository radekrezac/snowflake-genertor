## Snowflake Generator

Generates various scripts within Snowflake utilizing template table residing in ADMINISTRATION_UTILS.SCRIPT_TEMPLATE.

The procedure can be used in different ways:

Standalone directly in the Snowflake UI
Inside the loop in the Snowflake UI
Inside other Snowflake procedures
With external or 3rd party tools (dbt, snowSql, …)
Arguments
```
SCRIPT_TYPE    VARCHAR(250),
ACCES_TYPE    VARCHAR(250),
PARAMETER_VALUES    VARCHAR(500)
```
Returns

**VARCHAR(MAX)** – generated script or, when an error happens, a string starting with !Error
Usage:
```
CALL GENERATE_SCRIPT_FROM_TEMPLATE(<SCRIPT_TYPE>,<ACCES_TYPE>,<PARAMETER_VALUES>);
```
Parameters:

**<SCRIPT_TYPE>** = a value from SCRIPT_TYPE column of the SCRIPT_TEMPLATE table.

**<ACCES_TYPE>** = a value from ACCES_TYPE column of the SCRIPT_TEMPLATE table.

**<PARAMETER_VALUES>** = a string in the JSON format for each parameter name. Parameter names are defined in the column PARAMETER_NAMES of the SCRIPT_TEMPLATE table.

When we call the procedure with an empty string for the argument(s) we can get help info how to use the procedure:

Get general info on the usage of the procedure with the list of all script types:
```
CALL GENERATE_SCRIPT_FROM_TEMPLATE(’’,’’,’’);
```
Get a list of all access types for a given script type:
```
CALL GENERATE_SCRIPT_FROM_TEMPLATE(’<SCRIPT_TYPE>’,’’,’’);
```
Get usage info for a given script type and access type:
```
CALL GENERATE_SCRIPT_FROM_TEMPLATE(’<SCRIPT_TYPE>’, ’<ACCESS_TYPE >’,’’);
```
Using the procedure inside a loop - showing cursor loop for generating scripts for all schemas inside a database

