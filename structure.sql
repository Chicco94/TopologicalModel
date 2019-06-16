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
FOR r IN 1..9 LOOP
	FOR c IN 1..9 LOOP
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