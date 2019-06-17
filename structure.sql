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

RETURN 0;    -- return final result

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

RETURN 0;    -- return final result

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
create view intA(id) as
select A.id from topo.A
where not exists
(select poR.ida from poR
where poR.idb = A.id
and poR.ida not in (select id from topo.A));

create view clA(id) as
select distinct X.id from topo.X, poR, topo.A
where X.id = poR.idb and poR.ida = A.id;

create view bdA(id) as
select clA.id from clA
where clA.id not in (select id from intA);

create view extA(id) as
select id from topo.X
where id not in (select id from clA);


insert into topo.A (id) VALUES (55);
insert into topo.A (id) VALUES (56);
insert into topo.A (id) VALUES (65);
insert into topo.A (id) VALUES (45);
insert into topo.A (id) VALUES (54);
insert into topo.A (id) VALUES (46);
insert into topo.A (id) VALUES (64);
insert into topo.A (id) VALUES (44);
insert into topo.A (id) VALUES (66);