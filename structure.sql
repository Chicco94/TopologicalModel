CREATE SCHEMA TOPO;
CREATE DATABASE TOPO;

CREATE TYPE topo_set AS (id integer);
CREATE TABLE topo.X OF topo_set (PRIMARY KEY(id));

CREATE TYPE topo_rel AS (ida integer, idb integer);
CREATE TABLE R OF topo_rel (PRIMARY KEY(ida,idb));

/* mancano chiavi esterne
CREATE TABLE TOPO.R (
	ida INTEGER REFERENCES TOPO.X (id),
	idb INTEGER REFERENCES TOPO.X (id),
	PRIMARY KEY (ida, idb)
);*/


CREATE OR REPLACE FUNCTION fill_set(size int, _table regclass)
	RETURNS INTEGER AS
$BODY$
BEGIN
FOR r IN 1..size LOOP
	FOR c IN 1..size LOOP
		EXECUTE format('INSERT INTO %s (id) VALUES (%s*10+%s)', _table,r,c);
	END LOOP;
END LOOP;
RETURN size*size;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;



CREATE OR REPLACE FUNCTION fill_rel(size int, _table regclass)
	RETURNS INTEGER AS
$BODY$
BEGIN
FOR r IN 1..(size-1) LOOP
	FOR c IN 1..(size-1) LOOP
		-- inserisco la relazione con l'elemento sopra se esiste
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,r*10+c,(r+1)*10+c);
		-- inserisco la relazione con l'elemento a destra se esiste
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,r*10+c,r*10+(c+1));
	END LOOP;
END LOOP;
RETURN 2*(size-1)*(size-1);
EXCEPTION 
	WHEN foreign_key_violation 
	THEN RETURN -1;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;



/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato

 @return table chiusura riflessiva e transitiva della relazione sull'insieme dato
*/
CREATE OR REPLACE FUNCTION create_topology(_topo_set regclass,_topo_rel regclass)
	RETURNS TABLE (ida Integer,idb Integer) AS
$BODY$
BEGIN
RETURN QUERY EXECUTE format('
	select id as ida, id as idb from %s union 	-- reflexive
	select R.ida, R.idb from %s as R union		-- R
	select R1.ida, R2.idb					 	-- transitive
	from %s as R1 join %s as R2 on (R1.idb = R2.ida)
	', _topo_set, _topo_rel, _topo_rel, _topo_rel);
END;
$BODY$ LANGUAGE plpgsql VOLATILE;



-- presi un insieme
create table TOPO.A (
	id integer PRIMARY KEY REFERENCES TOPO.X (id)
);

insert into topo.A (id) VALUES (55);
insert into topo.A (id) VALUES (56);
insert into topo.A (id) VALUES (65);
insert into topo.A (id) VALUES (45);
insert into topo.A (id) VALUES (54);
insert into topo.A (id) VALUES (46);
insert into topo.A (id) VALUES (64);
insert into topo.A (id) VALUES (44);
insert into topo.A (id) VALUES (66);

-- di elementi randomici di X
/*
CREATE OR REPLACE FUNCTION fill_A()
  RETURNS INTEGER AS
$BODY$
BEGIN
INSERT INTO topo.A (id) (SELECT * FROM topo.X ORDER BY RANDOM() LIMIT RANDOM()*10);
RETURN 0;    -- return final result
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
*/


/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato
 @param _my_set insieme di cui sto chiedendo i punti interni

 @return table punti interni dell'insieme dato rispetto alla topologia data
*/
CREATE OR REPLACE FUNCTION topo_int(_topo_set regclass,_topo_rel regclass, _my_set regclass)
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
RETURN QUERY EXECUTE format('
	select A.id from %s as A
	where not exists
	(select poR.ida from %s as poR
	where poR.idb = A.id
	and poR.ida not in (select A1.id from %s as A1))
	', _my_set, _topo_rel, _my_set);
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato
 @param _my_set insieme di cui sto chiedendo la closure

 @return table closure dell'insieme dato rispetto alla topologia data
*/
CREATE OR REPLACE FUNCTION topo_cl(_topo_set regclass,_topo_rel regclass, _my_set regclass)
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
RETURN QUERY EXECUTE format('
	select distinct X.id from %s as X, %s as poR, %s as A
	where X.id = poR.idb and poR.ida = A.id
	',_topo_set, _topo_rel, _my_set);
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato
 @param _my_set insieme di cui sto chiedendo il contorno

 @return table contorno dell'insieme dato rispetto alla topologia data
*/
CREATE OR REPLACE FUNCTION topo_bd(_topo_set regclass,_topo_rel regclass, _my_set regclass)
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
	DROP TABLE IF EXISTS closure;
	DROP TABLE IF EXISTS interior;
	CREATE TEMP TABLE closure (c_id integer);
	insert into closure (c_id) (select * from topo_cl(_topo_set,_topo_rel, _my_set));
	CREATE TEMP TABLE interior (i_id integer);
	insert into interior (i_id) (select * from topo_int(_topo_set,_topo_rel, _my_set));

	RETURN QUERY 
	select c_id from closure AS C
	where c_id not in (select i_id from interior AS I);
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato
 @param _my_set insieme di cui sto chiedendo i punti esterni

 @return table punti esterni dell'insieme dato rispetto alla topologia data
*/
CREATE OR REPLACE FUNCTION topo_ext(_topo_set regclass,_topo_rel regclass, _my_set regclass)
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
	DROP TABLE IF EXISTS closure;
	CREATE TEMP TABLE closure (c_id integer);
	insert into closure (c_id) (select topo_cl(_topo_set,_topo_rel, _my_set));
	RETURN QUERY EXECUTE format('
	select X.id from %s as X
	where X.id not in (select * from closure)
	', _topo_set);
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


