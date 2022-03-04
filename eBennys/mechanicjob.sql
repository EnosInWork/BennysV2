INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_mechanic', 'Mecano', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_mechanic', 'Mecano', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_mechanic', 'Mecano', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('mechanic', 'Mecano')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('mechanic',0,'recrue','Recrue',12,'{}','{}'),
	('mechanic',1,'novice','Novice',24,'{}','{}'),
	('mechanic',2,'experimente','Experimente',36,'{}','{}'),
	('mechanic',3,'chief',"Chef d\'équipe",48,'{}','{}'),
	('mechanic',4,'boss','Patron',0,'{}','{}')
;

INSERT INTO `items` (name, label) VALUES
	('blowpipe', 'Chalumeaux'),
	('fixkit', 'Kit réparation'),
	('carokit', 'Kit carosserie')
;
