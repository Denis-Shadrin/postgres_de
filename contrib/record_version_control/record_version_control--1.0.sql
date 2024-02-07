CREATE FUNCTION check_changes(table_name_param TEXT)
RETURNS VOID AS $$
DECLARE
    table_exists BOOLEAN;					--check table existence
    column_names_with_type TEXT;			--columnname_tablename type, ...
    column_names_without_type TEXT;			--columnname_tablename, ...
    NEW_and_column_names_base_table TEXT; 	--NEW.columnname, ...
    OLD_and_column_names_base_table TEXT; 	--OLD.columnname, ...
BEGIN
    --checking table existence
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_name = table_name_param
    ) INTO table_exists;
    
    --RAISE NOTICE 'bool: %', table_exists;

    IF table_exists THEN
        SELECT STRING_AGG( column_name || '_' || table_name_param  || ' ' || data_type, ', ')
        INTO column_names_with_type
        FROM information_schema.columns
        WHERE table_name = table_name_param;

		SELECT STRING_AGG( column_name || '_' || table_name_param , ', ')
        INTO column_names_without_type
        FROM information_schema.columns
        WHERE table_name = table_name_param;
		
		SELECT STRING_AGG('NEW.' || column_name , ', ')
        INTO NEW_and_column_names_base_table
        FROM information_schema.columns
        WHERE table_name = table_name_param;
		
		SELECT STRING_AGG('OLD.' || column_name , ', ')
        INTO OLD_and_column_names_base_table
        FROM information_schema.columns
        WHERE table_name = table_name_param;
		
        column_names_with_type := 'Id SERIAL PRIMARY KEY, when_add timestamp, operation text, who_adds text DEFAULT current_user, ' || column_names_with_type;
		
        EXECUTE FORMAT('CREATE TABLE %I_log (%s)', table_name_param, column_names_with_type);
        RAISE NOTICE 'Table %_log created successfully with columns: %', table_name_param, column_names_with_type;
		
		--INSERT TRIGGER
		EXECUTE FORMAT(
		'CREATE FUNCTION %I_insert()
		RETURNS TRIGGER AS
		$i_trigger_function$
		BEGIN
			INSERT INTO %I_log (when_add, operation , %s)
			VALUES (CURRENT_TIMESTAMP, ''INSERT'', %s);
			RETURN NEW;
		END;
		$i_trigger_function$ LANGUAGE plpgsql;',
		table_name_param, table_name_param, column_names_without_type, NEW_and_column_names_base_table);
		
		EXECUTE FORMAT(
		'CREATE TRIGGER %I_insert_trigger
		AFTER INSERT ON %I
		FOR EACH ROW
		EXECUTE PROCEDURE %I_insert();',
		table_name_param, table_name_param, table_name_param
		);
		
		--UPDATE TRIGGER
		EXECUTE FORMAT(
		'CREATE FUNCTION %I_update()
		RETURNS TRIGGER AS
		$u_trigger_function$
		BEGIN
			INSERT INTO %I_log (when_add, operation , %s)
			VALUES (CURRENT_TIMESTAMP, ''UPDATE'', %s);
			RETURN NEW;
		END;
		$u_trigger_function$ LANGUAGE plpgsql;',
		table_name_param, table_name_param, column_names_without_type, NEW_and_column_names_base_table);
		
		EXECUTE FORMAT(
		'CREATE TRIGGER %I_update_trigger
		AFTER UPDATE ON %I
		FOR EACH ROW
		EXECUTE PROCEDURE %I_update();',
		table_name_param, table_name_param, table_name_param
		);
		
		--DELETE TRIGGER
		EXECUTE FORMAT(
		'CREATE FUNCTION %I_delete()
		RETURNS TRIGGER AS
		$d_trigger_function$
		BEGIN
			INSERT INTO %I_log (when_add, operation , %s)
			VALUES (CURRENT_TIMESTAMP, ''DELETE'', %s);
			RETURN NEW;
		END;
		$d_trigger_function$ LANGUAGE plpgsql;',
		table_name_param, table_name_param, column_names_without_type, OLD_and_column_names_base_table);
		
		EXECUTE FORMAT(
		'CREATE TRIGGER %I_delete_trigger
		AFTER DELETE ON %I
		FOR EACH ROW
		EXECUTE PROCEDURE %I_delete();',
		table_name_param, table_name_param, table_name_param
		);
		
    ELSE
        RAISE NOTICE 'Table % not found. Skipping creation.', table_name_param;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION drop_checking_changes(table_name_param TEXT)
RETURNS VOID AS $$
DECLARE

BEGIN
DROP TRIGGER IF EXISTS test_table_insert_trigger ON test_table;
DROP FUNCTION IF EXISTS test_table_insert() CASCADE;

DROP TRIGGER IF EXISTS test_table_update_trigger ON test_table;
DROP FUNCTION IF EXISTS test_table_update() CASCADE;

DROP TRIGGER IF EXISTS test_table_delete_trigger ON test_table;
DROP FUNCTION IF EXISTS test_table_delete() CASCADE;
DROP TABLE test_table_log;
END;
$$ LANGUAGE plpgsql;
