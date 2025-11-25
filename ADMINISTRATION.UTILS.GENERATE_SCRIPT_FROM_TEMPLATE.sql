use role accountadmin;

CREATE OR REPLACE PROCEDURE ADMINISTRATION.UTILS.GENERATE_SCRIPT_FROM_TEMPLATE("SCRIPT_TYPE" VARCHAR(250), "ACCES_TYPE" VARCHAR(250), "PARAMETER_VALUES" VARCHAR(5000))
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
STRICT
EXECUTE AS OWNER
AS '
var error = "";  
//check existence of SCRIPT_TEMPLATE_CUSTOM
var customTableExists = false;
var sql =  "select exists ( select 1 from information_schema.tables where table_catalog=''ADMINISTRATION'' and table_schema = ''UTILS'' and table_name = ''SCRIPT_TEMPLATE_CUSTOM'')";
var stmt = null;
var result = null;
var rowCount = 0;
try {
  stmt = snowflake.createStatement({ sqlText: sql });                
  result = stmt.execute();
  var rowCount = result.getRowCount();
  // No record with template found -> return usage
  if (rowCount == 0) {
    customTableExists = false;
  }
  else
  {
    result.next();
    customTableExists = result.getColumnValue(1);
  }
} catch
{
   error = `!Error: When checking existence of SCRIPT_TEMPLATE_CUSTOM.`; 
}
//select template according SCRIPT_TYPE and ACCES_TYPE
sql =  `select PARAMETER_NAMES, PARAMETER_SUBSTITUTE_VALUES, COMPUTED_PARAMS, TEMPLATE, USAGE from ADMINISTRATION_SE.utils.SCRIPT_TEMPLATE where SCRIPT_TYPE = ''${SCRIPT_TYPE}'' AND ACCES_TYPE = ''${ACCES_TYPE}''`;
if (customTableExists == true) {
  sql =  sql + ` union all select PARAMETER_NAMES, PARAMETER_SUBSTITUTE_VALUES, COMPUTED_PARAMS, TEMPLATE, USAGE from administration.utils.SCRIPT_TEMPLATE_CUSTOM where SCRIPT_TYPE = ''${SCRIPT_TYPE}'' AND ACCES_TYPE = ''${ACCES_TYPE}''`;
}
try{
  var stmt = snowflake.createStatement({ sqlText: sql });                
  var result = stmt.execute();
  var rowCount = result.getRowCount();
  // No record with template found -> return usage
  if (rowCount == 0) {
    error = `!Error: Script with given SCRIPT_TYPE and  ACCES_TYPE does not exist.`;
  }
}catch{
  error = `!Error: When selecting template according SCRIPT_TYPE and ACCES_TYPE`;
}  
if (error.length > 0) {
  // Check SCRIPT_TYPE
  var availaibleScriptTypes = "";
  var availaibleAccessTypes = "";
  if (!SCRIPT_TYPE) {
    // List all Script Types
    sql =  `select SCRIPT_TYPE from ADMINISTRATION_SE.utils.SCRIPT_TEMPLATE GROUP BY SCRIPT_TYPE`;
	if (customTableExists == true) {
      sql =  sql + ` union all select SCRIPT_TYPE from ADMINISTRATION.utils.SCRIPT_TEMPLATE_CUSTOM GROUP BY SCRIPT_TYPE`;
	}  
    stmt = snowflake.createStatement({ sqlText: sql });                
    result = stmt.execute();
    rowCount = result.getRowCount();
    if (rowCount > 0) {
      availaibleScriptTypes = "Available values for SCRIPT_TYPE:\\n--------------------------------\\n";   
      while (result.next()) {
        availaibleScriptTypes = availaibleScriptTypes + result.getColumnValue(1) + "\\n";
      }
    }  
  } else {
    // List all Access Types
    sql =  `select ACCES_TYPE from ADMINISTRATION_SE.utils.SCRIPT_TEMPLATE where SCRIPT_TYPE = ''${SCRIPT_TYPE}''  GROUP BY ACCES_TYPE`;
	if (customTableExists == true) {
      sql =  sql + ` union all select ACCES_TYPE from ADMINISTRATION.utils.SCRIPT_TEMPLATE_CUSTOM where SCRIPT_TYPE = ''${SCRIPT_TYPE}''  GROUP BY ACCES_TYPE`;
	} 
    stmt = snowflake.createStatement({ sqlText: sql });                
    result = stmt.execute();
    rowCount = result.getRowCount();
    if (rowCount > 0) {
      availaibleAccessTypes = `Available values for ACCES_TYPE where SCRIPT_TYPE = ''${SCRIPT_TYPE}'':\\n---------------------------------------------------------------------------\\n`;   
      while (result.next()) {
        availaibleAccessTypes = availaibleAccessTypes + result.getColumnValue(1) + "\\n";
      }
    }  
  }
  // Usage error with list of SCRIPT_TYPE or ACCES_TYPE
  var procUsage = "Usage: CALL GENERATE_SCRIPT_FROM_TEMPLATE(<SCRIPT_TYPE>,<ACCES_TYPE>,<PARAMETER_VALUES>);\\nParameters:\\n\\t<SCRIPT_TYPE> = value from SCRIPT_TYPE column of the script template tables.\\n\\t<ACCES_TYPE> = value from ACCES_TYPE column of the script template tables.\\n\\t<PARAMETER_VALUES> = string in the JSON format for each parameter name. Paramater names are defined in the column PARAMETER_NAMES of the script template tables.\\n\\nTo get detailed info about PARAMETER_VALUES of the specified script template, call procedure with empty string for PARAMETER_VALUES:\\nCALL GENERATE_SCRIPT_FROM_TEMPLATE(''TAGGED_OBJECT'',''ADD_TAG'','''')";
     error = `${error}\\n\\n${procUsage}`;
     if (availaibleScriptTypes) error = `${error}\\n\\n${availaibleScriptTypes}`
     else error = `${error}\\n\\n${availaibleAccessTypes}`
     return error;
  }  
  result.next();
   // retrieve column values
   var parameterNames = result.getColumnValue(1);
   var parameterSubstituteValuesJSON = result.getColumnValue(2);
   var parameterComputedJSON = result.getColumnValue(3);
   var scriptTemplate = result.getColumnValue(4);
   var usage = result.getColumnValue(5);
   // check if PARAMETER_VALUES is empty -> return usage
   if (!PARAMETER_VALUES) {
     error = `!Error: Empty PARAMETER_VALUES:\\n\\n${usage}`;
   }
   if (error.length > 0) return error;
   // try parse the PARAMETER_VALUES
   try
   {
     var parameterValues = JSON.parse(PARAMETER_VALUES);
   }
   catch (err)  {
     error = `!Error: Failed to parse PARAMETER_VALUES: ${PARAMETER_VALUES}`; 
   }
   if (error.length > 0) return error;   
   // check parameters values
   var parameterNamesArray = parameterNames.split('','');
   parameterNamesArray.forEach(parameterName => {
     if (!parameterValues[parameterName] || typeof parameterValues[parameterName] === undefined) {
       error = error + `!Error: Cannot find parameter ${parameterName} in PARAMETER_VALUES: ${PARAMETER_VALUES}.\\n`
     }
   });
   if (error.length > 0) {
     error = `${error}.\\n\\n${usage}`; 
     return error;
   }  
   // replacing parameter values by substitute values
   if (parameterSubstituteValuesJSON && typeof parameterSubstituteValuesJSON !== undefined) {
     try
     {
       var parameterSubstituteValues = JSON.parse(parameterSubstituteValuesJSON);
     }
     catch (err)  {
       error = `!Error: Failed to parse parameterSubstituteValuesJSON: ${parameterSubstituteValuesJSON}.`; 
     }
     if (error.length == 0){
       Object.keys(parameterSubstituteValues).forEach(parameterName => {
         var parameterValue = parameterValues[parameterName];
         var substituteValue = parameterSubstituteValues[parameterName][parameterValue];
         if ( parameterValue && typeof parameterValue !== undefined && substituteValue && typeof substituteValue !== undefined) {
           parameterValues[parameterName] = substituteValue;
         }
       })
     }
   }
   if (error.length > 0) return error;
   var oldString = '''';
   var newString = '''';
   var script = scriptTemplate;
   parameterNamesArray.forEach(parameterName => {
     oldString = `<${parameterName}>`;
     newString = parameterValues[parameterName];
     script = script.replaceAll(oldString,newString);
   });
   //Computed parameters
   if (parameterComputedJSON && typeof parameterComputedJSON !== undefined) {
     try
     {
       var parameterComputed = JSON.parse(parameterComputedJSON);
     }
     catch (err)  {
       error = `!Error: Failed to parse parameterComputedJSON: ${parameterComputedJSON}.`; 
     }
     if (error.length == 0){
       Object.keys(parameterComputed).forEach(parameterName => {
         // Execute computed query
         sql = parameterComputed[parameterName];
         // Replace params in a query
         parameterNamesArray.forEach(parameterName => {
           oldString = `<${parameterName}>`;
           newString = parameterValues[parameterName];
           sql = sql.replaceAll(oldString,newString);
         });
         stmt = snowflake.createStatement({ sqlText: sql });                
         result = stmt.execute();
         rowCount = result.getRowCount();
         if (rowCount > 0) {
           result.next();
           parameterComputed[parameterName] = result.getColumnValue(1);
         }
       })
       // Replace computed params
       Object.keys(parameterComputed).forEach(parameterName => {
         oldString = `<<${parameterName}>>`;
         newString = parameterComputed[parameterName];
         script = script.replaceAll(oldString,newString);
       });
     }
   }   
   //Adding ; at the end of the line
   var position = script.search(";");
   if (position < 0) {
     script = script.replaceAll("\\n",";\\n")   
     script = script + ";";
   }
   return script ;
';