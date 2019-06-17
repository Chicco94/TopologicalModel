CREATE DATABASE myTOPO;

CREATE TABLE TOPO.X (
	id INTEGER PRIMARY KEY
);

CREATE TABLE TOPO.R (
	ida INTEGER REFERENCES TOPO.X (id),
	idb INTEGER REFERENCES TOPO.X (id),
	PRIMARY KEY (ida, idb)
);


CREATE OR REPLACE FUNCTION fill_X()
  RETURNS INTEGER AS
$BODY$
BEGIN
FOR r IN 1..9 LOOP
	FOR c IN 1..9 LOOP
		INSERT INTO topo.x (id) VALUES (r*10+c);
	END LOOP;
END LOOP;
RETURN 0;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;



CREATE OR REPLACE FUNCTION fill_R()
  RETURNS INTEGER AS
$BODY$
BEGIN
FOR r IN 1..8 LOOP
	FOR c IN 1..8 LOOP
		-- inserisco la relazione con l'elemento sopra se esiste
		INSERT INTO topo.r (ida,idb) VALUES (r*10+c, (r+1)*10+c);
		-- inserisco la relazione con l'elemento a destra se esiste
		INSERT INTO topo.r (ida,idb) VALUES (r*10+c, r*10+(c+1));
		
	END LOOP;
END LOOP;
RETURN 0;
EXCEPTION 
	WHEN foreign_key_violation 
	THEN RETURN 1;

END;
$BODY$ LANGUAGE plpgsql VOLATILE;


-- transitive and reflexive closure of r
create view poR(ida, idb) as
	select id as ida, id as idb from topo.X union -- reflexive
	select R.ida, R.idb from topo.R union		 -- R
	select R.ida, R2.idb					 -- transitive
	from topo.R join topo.R as R2 on (R.idb = R2.ida);


-- presi due insiemi
create table TOPO.A (
	id integer PRIMARY KEY REFERENCES TOPO.X (id)
);
create table TOPO.B (
	id integer PRIMARY KEY REFERENCES TOPO.X (id)
);

-- di elementi randomici di X
CREATE OR REPLACE FUNCTION fill_A()
  RETURNS INTEGER AS
$BODY$
BEGIN
INSERT INTO topo.A (id) (SELECT * FROM topo.X ORDER BY RANDOM() LIMIT RANDOM()*10);
RETURN 0;    -- return final result
END;
$BODY$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION fill_B()
  RETURNS INTEGER AS
$BODY$
BEGIN
INSERT INTO topo.B (id) (SELECT * FROM topo.X ORDER BY RANDOM() LIMIT RANDOM()*10);
RETURN 0;    -- return final result
END;
$BODY$ LANGUAGE plpgsql VOLATILE;


-- punti interni
CREATE OR REPLACE FUNCTION topo_int()
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
RETURN QUERY 
	select A.id from topo.A
	where not exists
	(select poR.ida from poR
	where poR.idb = A.id
	and poR.ida not in (select A1.id from topo.A as A1));
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;

-- closure
CREATE OR REPLACE FUNCTION topo_cl()
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
RETURN QUERY 
	select distinct X.id from topo.X, poR, topo.A
	where X.id = poR.idb and poR.ida = A.id;
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION topo_bd()
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
	DROP TABLE IF EXISTS closure;
	DROP TABLE IF EXISTS interior;
	CREATE TEMP TABLE closure  ON COMMIT DELETE ROWS AS (select topo_cl() );
	CREATE TEMP TABLE interior ON COMMIT DELETE ROWS AS (select topo_int());
	RETURN QUERY 
	select C.id from closure AS C
	where C.id not in (select I.id from interior AS I);
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION topo_ext()
	RETURNS TABLE (id Integer) AS
$BODY$
BEGIN
	CREATE TEMP TABLE closure (c_id integer);
	insert into closure (c_id) (select topo_cl());
	RETURN QUERY 
	select T.id from topo.X as T
	where T.id not in (select C_id from closure);
END; $BODY$
LANGUAGE 'plpgsql' VOLATILE;


insert into topo.A (id) VALUES (55);
insert into topo.A (id) VALUES (56);
insert into topo.A (id) VALUES (65);
insert into topo.A (id) VALUES (45);
insert into topo.A (id) VALUES (54);
insert into topo.A (id) VALUES (46);
insert into topo.A (id) VALUES (64);
insert into topo.A (id) VALUES (44);
insert into topo.A (id) VALUES (66);