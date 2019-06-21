CREATE SCHEMA TOPO;

-- creo il tipo "set di una topologia", potrebbe essere necessario in futuro
CREATE TYPE topo_set AS (id integer);
CREATE TABLE topo.X OF topo_set (PRIMARY KEY(id));

-- creo il tipo "relazione di una topologia", potrebbe essere necessario in futuro
CREATE TYPE  topo_rel AS (ida integer, idb integer);
CREATE TABLE topo.R OF topo_rel (PRIMARY KEY(ida,idb));
-- se l'elemento viene eliminato dal insieme di costruzione deve scomparire dalla topologia
ALTER  TABLE topo.R ADD FOREIGN KEY (ida) REFERENCES topo.X (id);
ALTER  TABLE topo.R ADD FOREIGN KEY (idb) REFERENCES topo.X (id);



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



-- Tuple R(11, 12) denotes e.g. that 12 ∈ bd{11}
CREATE OR REPLACE FUNCTION fill_rel(size int, _table regclass)
	RETURNS INTEGER AS
$BODY$
BEGIN
-- angoli
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,11,12);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,11,21);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,19,18);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,19,28);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,91,92);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,91,81);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,99,89);
EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,99,98);

-- ciclo sui 4 bordi contemporaneamente
FOR i IN 2..(size-1) LOOP
	IF (i % 2 = 1) THEN -- sono in una faccia
		-- celle colonna a sinistra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,10+i,10+i+1); -- bordo sopra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,10+i,10+i-1); -- bordo sotto
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,10+i,20+i  ); -- bordo a destra

		-- celle colonna a destra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,90+i,90+i+1); -- bordo sopra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,90+i,90+i-1); -- bordo sotto
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,90+i,80+i  ); -- bordo a sinistra

		-- celle riga sotto
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+1,(10*i)+2); -- bordo sopra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+1,(10*(i-1))+1); -- bordo a sinistra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+1,(10*(i+1))+1); -- bordo a destra

		-- celle riga sopra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+9,(10*i)+8); -- bordo sotto
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+9,(10*(i-1))+9); -- bordo a sinistra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+9,(10*(i+1))+9); -- bordo a destra
	ELSE -- sono in un lato
		-- lato a sinistra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,10+i,20+i  ); -- bordo a destra
		-- lato a destra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,90+i,80+i  ); -- bordo a sinistra
		-- lato sotto
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+1,(10*i)+2); -- bordo sopra
		-- lato sopra
		EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+9,(10*i)+8); -- bordo sotto
	END IF;
END LOOP;

-- ciclo sulle celle interne
FOR i IN 2..(size-1) LOOP
	FOR j IN 2..(size-1) LOOP
		IF (i % 2 = 1 and j % 2 = 1) THEN -- sono in una faccia
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*i)+j+1);  -- bordo sopra
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*i)+j-1);  -- bordo sotto
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*(i+1))+j);  -- bordo a sinistra
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*(i-1))+j);  -- bordo a destra
		ELSIF (i % 2 = 1 and  j % 2 = 0) THEN -- sono in un lato orrizzontale
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*(i+1))+j); -- bordo a destra
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*(i-1))+j); -- bordo a sinistra
		ELSIF (i % 2 = 0 and  j % 2 = 1) THEN -- sono in un lato verticale
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*i)+j+1); -- bordo a sopra
			EXECUTE format('INSERT INTO %s (ida,idb) VALUES (%s, %s)',_table,(10*i)+j,(10*i)+j-1); -- bordo a sotto
		END IF;
		-- se non si verifica nessuna delle precedenti condizioni sono su un putno
	END LOOP;
END LOOP;
RETURN 0;
EXCEPTION 
	WHEN foreign_key_violation 
	THEN RETURN -1;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;



/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato

 @return table chiusura riflessiva e transitiva della relazione sull'insieme dato

 @usage insert into topo.por (select ida,idb  from create_topology('topo.x','topo.r'));
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

-- presi un insieme
create table TOPO.B (
	id integer PRIMARY KEY REFERENCES TOPO.X (id)
);

-- celle interne
insert into topo.B (id) VALUES (47);
insert into topo.B (id) VALUES (37);
insert into topo.B (id) VALUES (36);
insert into topo.B (id) VALUES (35);
insert into topo.B (id) VALUES (57);

-- sotto e sinistra
insert into topo.B (id) VALUES (34);
insert into topo.B (id) VALUES (44);
insert into topo.B (id) VALUES (45);
insert into topo.B (id) VALUES (46);
insert into topo.B (id) VALUES (56);
insert into topo.B (id) VALUES (66);
insert into topo.B (id) VALUES (67);
-- sopra
insert into topo.B (id) VALUES (68);
insert into topo.B (id) VALUES (58);
insert into topo.B (id) VALUES (48);
insert into topo.B (id) VALUES (38); 
-- lato sinistro
insert into topo.B (id) VALUES (28);
insert into topo.B (id) VALUES (27);
insert into topo.B (id) VALUES (26);
insert into topo.B (id) VALUES (25);
insert into topo.B (id) VALUES (24);

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

 funziona correttamente solo se funzionano correttamente interior e closure
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

 ritorna tutto ciò che è esterno alla closure
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



/**
 @param _topo_set insieme di valori su cui si appoggia la topologia
 @param _topo_rel relazione sull'insieme sopra citato
 @param _setA insieme di cui sto chiedendo la matrice di intersezione
 @param _setB insieme di cui sto chiedendo la matrice di intersezione

 @return table la matrice di intersezione degli insieme dati rispetto alla topologia data

 ritorna tutto ciò che è esterno alla closure
*/
CREATE OR REPLACE FUNCTION topo_ext(_topo_set regclass,_topo_rel regclass, _setA regclass, _setB regclass)
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

select
exists(select * from topo.intA as ia, topo.intB as ib where ia.id=ib.id)
as iaib,
exists(select * from topo.bdA  as da, topo.intB as ib where da.id=ib.id)
as daib,
exists(select * from topo.extA as xa, topo.intB as ib where xa.id=ib.id)
as xaib,
exists(select * from topo.intA as ia, topo.bdB  as db where ia.id=db.id)
as iadb,
exists(select * from topo.bdA  as da, topo.bdB  as db where da.id=db.id)
as dadb,
exists(select * from topo.extA as xa, topo.bdB  as db where xa.id=db.id)
as xadb,
exists(select * from topo.intA as ia, topo.extB as xb where ia.id=xb.id)
as iaxb,
exists(select * from topo.bdA  as da, topo.extB as xb where da.id=xb.id)
as daxb,
exists(select * from topo.extA as xa, topo.extB as xb where xa.id=xb.id)
as xaxb;




-- svuota e riempi
insert into topo.intb 	(select topo_int('topo.x','topo.por','topo.b'));
insert into topo.bdb 	(select topo_bd('topo.x','topo.por','topo.b'));
insert into topo.clb 	(select topo_cl('topo.x','topo.por','topo.b'));
insert into topo.extb 	(select topo_ext('topo.x','topo.por','topo.b'));

insert into topo.inta 	(select topo_int('topo.x','topo.por','topo.a'));
insert into topo.bda 	(select topo_bd('topo.x','topo.por','topo.a'));
insert into topo.cla 	(select topo_cl('topo.x','topo.por','topo.a'));
insert into topo.exta 	(select topo_ext('topo.x','topo.por','topo.a'));

truncate table topo.intb cascade;
truncate table topo.bdb  cascade;
truncate table topo.clb  cascade;
truncate table topo.extb cascade;
truncate table topo.inta cascade;
truncate table topo.bda  cascade;
truncate table topo.cla  cascade;
truncate table topo.exta cascade;