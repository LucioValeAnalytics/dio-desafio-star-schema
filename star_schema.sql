-- =========================================================
-- DIO | Desafio 5a - Modelo Dimensional Universidade
-- Star Schema | PostgreSQL / Neon
-- =========================================================
--
-- Objetivo:
-- Criar um Data Warehouse dimensional com foco na análise
-- das atividades de ensino dos professores.
--
-- Grão da fato:
-- Uma linha representa uma oferta de uma disciplina por um
-- professor, em um curso/departamento e em uma determinada data,
-- com uma carga horária associada.
--
-- Dimensões:
--   dim_professor
--   dim_departamento
--   dim_curso
--   dim_disciplina
--   dim_data
--
-- Fato:
--   fato_ensino
--   Medida: carga_horaria
--
-- Observação:
-- O script utiliza PostgreSQL e pode ser executado no Neon.
-- =========================================================

-- =========================================================
-- 0. PREPARAÇÃO
-- =========================================================

-- Para recriar o DW do zero em ambiente de desenvolvimento,
-- descomente a linha abaixo.
-- ATENÇÃO: ela apaga todo o schema e suas tabelas.
-- DROP SCHEMA IF EXISTS universidade_dw CASCADE;

CREATE SCHEMA IF NOT EXISTS universidade_dw;

-- =========================================================
-- 1. DIMENSÃO PROFESSOR
-- =========================================================

CREATE TABLE universidade_dw.dim_professor (
    professor_key       INTEGER GENERATED ALWAYS AS IDENTITY,
    id_professor_origem INTEGER NOT NULL,
    nome_professor      VARCHAR(100) NOT NULL,

    CONSTRAINT pk_dim_professor
        PRIMARY KEY (professor_key),

    CONSTRAINT uq_dim_professor_origem
        UNIQUE (id_professor_origem)
);

-- =========================================================
-- 2. DIMENSÃO DEPARTAMENTO
-- =========================================================

CREATE TABLE universidade_dw.dim_departamento (
    departamento_key         INTEGER GENERATED ALWAYS AS IDENTITY,
    id_departamento_origem   INTEGER NOT NULL,
    nome_departamento        VARCHAR(100) NOT NULL,
    campus                   VARCHAR(100) NOT NULL,
    id_professor_coordenador INTEGER,

    CONSTRAINT pk_dim_departamento
        PRIMARY KEY (departamento_key),

    CONSTRAINT uq_dim_departamento_origem
        UNIQUE (id_departamento_origem)
);

-- =========================================================
-- 3. DIMENSÃO CURSO
-- =========================================================

CREATE TABLE universidade_dw.dim_curso (
    curso_key       INTEGER GENERATED ALWAYS AS IDENTITY,
    id_curso_origem INTEGER NOT NULL,
    nome_curso      VARCHAR(150) NOT NULL,

    CONSTRAINT pk_dim_curso
        PRIMARY KEY (curso_key),

    CONSTRAINT uq_dim_curso_origem
        UNIQUE (id_curso_origem)
);

-- =========================================================
-- 4. DIMENSÃO DISCIPLINA
-- =========================================================

CREATE TABLE universidade_dw.dim_disciplina (
    disciplina_key       INTEGER GENERATED ALWAYS AS IDENTITY,
    id_disciplina_origem INTEGER NOT NULL,
    nome_disciplina      VARCHAR(150) NOT NULL,

    CONSTRAINT pk_dim_disciplina
        PRIMARY KEY (disciplina_key),

    CONSTRAINT uq_dim_disciplina_origem
        UNIQUE (id_disciplina_origem)
);

-- =========================================================
-- 5. DIMENSÃO DATA
-- =========================================================
-- A dimensão de datas foi criada porque o modelo relacional
-- fornecido não possui datas suficientes para a análise.
-- O período adotado neste exercício é 2025-01-01 a 2027-12-31.

CREATE TABLE universidade_dw.dim_data (
    data_key      INTEGER PRIMARY KEY,
    data          DATE NOT NULL,
    ano           INTEGER NOT NULL,
    semestre      INTEGER NOT NULL,
    trimestre     INTEGER NOT NULL,
    mes           INTEGER NOT NULL,
    nome_mes      VARCHAR(20) NOT NULL,
    dia           INTEGER NOT NULL,
    dia_semana    VARCHAR(20) NOT NULL,

    CONSTRAINT uq_dim_data_data
        UNIQUE (data),

    CONSTRAINT ck_dim_data_semestre
        CHECK (semestre IN (1, 2)),

    CONSTRAINT ck_dim_data_trimestre
        CHECK (trimestre BETWEEN 1 AND 4),

    CONSTRAINT ck_dim_data_mes
        CHECK (mes BETWEEN 1 AND 12),

    CONSTRAINT ck_dim_data_dia
        CHECK (dia BETWEEN 1 AND 31)
);

INSERT INTO universidade_dw.dim_data (
    data_key,
    data,
    ano,
    semestre,
    trimestre,
    mes,
    nome_mes,
    dia,
    dia_semana
)
SELECT
    TO_CHAR(d::DATE, 'YYYYMMDD')::INTEGER,
    d::DATE,
    EXTRACT(YEAR FROM d)::INTEGER,

    CASE
        WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1
        ELSE 2
    END,

    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,

    CASE EXTRACT(MONTH FROM d)::INTEGER
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END,

    EXTRACT(DAY FROM d)::INTEGER,

    CASE EXTRACT(ISODOW FROM d)::INTEGER
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END

FROM GENERATE_SERIES(
    DATE '2025-01-01',
    DATE '2027-12-31',
    INTERVAL '1 day'
) AS serie(d);

-- =========================================================
-- 6. TABELA FATO
-- =========================================================
-- A fato registra o evento de ensino e suas chaves dimensionais.
-- A medida é carga_horaria.

CREATE TABLE universidade_dw.fato_ensino (
    fato_ensino_key  INTEGER GENERATED ALWAYS AS IDENTITY,

    professor_key    INTEGER NOT NULL,
    departamento_key INTEGER NOT NULL,
    curso_key        INTEGER NOT NULL,
    disciplina_key   INTEGER NOT NULL,
    data_key         INTEGER NOT NULL,

    carga_horaria    INTEGER NOT NULL,

    CONSTRAINT pk_fato_ensino
        PRIMARY KEY (fato_ensino_key),

    CONSTRAINT fk_fato_professor
        FOREIGN KEY (professor_key)
        REFERENCES universidade_dw.dim_professor (professor_key),

    CONSTRAINT fk_fato_departamento
        FOREIGN KEY (departamento_key)
        REFERENCES universidade_dw.dim_departamento (departamento_key),

    CONSTRAINT fk_fato_curso
        FOREIGN KEY (curso_key)
        REFERENCES universidade_dw.dim_curso (curso_key),

    CONSTRAINT fk_fato_disciplina
        FOREIGN KEY (disciplina_key)
        REFERENCES universidade_dw.dim_disciplina (disciplina_key),

    CONSTRAINT fk_fato_data
        FOREIGN KEY (data_key)
        REFERENCES universidade_dw.dim_data (data_key),

    CONSTRAINT ck_fato_carga_horaria
        CHECK (carga_horaria > 0),

    CONSTRAINT uq_fato_ensino_grain
        UNIQUE (
            professor_key,
            departamento_key,
            curso_key,
            disciplina_key,
            data_key
        )
);

-- =========================================================
-- 7. CARGA DAS DIMENSÕES
-- =========================================================

INSERT INTO universidade_dw.dim_professor (
    id_professor_origem,
    nome_professor
)
VALUES
    (101, 'Ana Souza'),
    (102, 'Carlos Oliveira'),
    (103, 'Mariana Costa'),
    (104, 'João Pereira'),
    (105, 'Fernanda Lima'),
    (106, 'Ricardo Alves');

INSERT INTO universidade_dw.dim_departamento (
    id_departamento_origem,
    nome_departamento,
    campus,
    id_professor_coordenador
)
VALUES
    (10, 'Computação', 'Campus Central', 101),
    (20, 'Administração', 'Campus Central', 102),
    (30, 'Engenharias', 'Campus Norte', 103),
    (40, 'Ciências Humanas', 'Campus Sul', 104);

INSERT INTO universidade_dw.dim_curso (
    id_curso_origem,
    nome_curso
)
VALUES
    (101, 'Sistemas de Informação'),
    (102, 'Ciência de Dados'),
    (201, 'Administração'),
    (301, 'Engenharia de Produção'),
    (302, 'Engenharia de Software'),
    (401, 'Psicologia');

INSERT INTO universidade_dw.dim_disciplina (
    id_disciplina_origem,
    nome_disciplina
)
VALUES
    (1001, 'Banco de Dados'),
    (1002, 'SQL'),
    (1003, 'Programação'),
    (1004, 'Estatística'),
    (1005, 'Gestão de Projetos'),
    (1006, 'Engenharia de Software'),
    (1007, 'Gestão Financeira'),
    (1008, 'Psicologia Organizacional');

-- =========================================================
-- 8. CARGA DA FATO
-- =========================================================
-- As datas e os IDs abaixo são dados simulados para representar
-- ofertas de disciplinas, conforme permitido pelo enunciado.

WITH ofertas (
    id_professor_origem,
    id_departamento_origem,
    id_curso_origem,
    id_disciplina_origem,
    data_oferta,
    carga_horaria
) AS (
    VALUES
        (101, 10, 101, 1001, DATE '2026-08-10', 60),
        (101, 10, 101, 1002, DATE '2026-08-11', 40),
        (102, 20, 201, 1007, DATE '2026-08-12', 60),
        (102, 20, 201, 1005, DATE '2026-08-13', 40),
        (103, 30, 302, 1006, DATE '2026-08-14', 80),
        (103, 30, 301, 1004, DATE '2026-08-15', 60),
        (104, 40, 401, 1008, DATE '2026-08-18', 60),
        (104, 10, 102, 1004, DATE '2026-08-19', 40),
        (105, 10, 102, 1003, DATE '2026-08-20', 80),
        (106, 30, 302, 1003, DATE '2026-08-21', 60)
)
INSERT INTO universidade_dw.fato_ensino (
    professor_key,
    departamento_key,
    curso_key,
    disciplina_key,
    data_key,
    carga_horaria
)
SELECT
    p.professor_key,
    d.departamento_key,
    c.curso_key,
    dis.disciplina_key,
    dt.data_key,
    o.carga_horaria
FROM ofertas o
JOIN universidade_dw.dim_professor p
    ON p.id_professor_origem = o.id_professor_origem
JOIN universidade_dw.dim_departamento d
    ON d.id_departamento_origem = o.id_departamento_origem
JOIN universidade_dw.dim_curso c
    ON c.id_curso_origem = o.id_curso_origem
JOIN universidade_dw.dim_disciplina dis
    ON dis.id_disciplina_origem = o.id_disciplina_origem
JOIN universidade_dw.dim_data dt
    ON dt.data = o.data_oferta;

-- =========================================================
-- 9. VALIDAÇÕES DO MODELO
-- =========================================================

SELECT
    COUNT(*) AS quantidade_datas,
    MIN(data) AS primeira_data,
    MAX(data) AS ultima_data
FROM universidade_dw.dim_data;

SELECT
    COUNT(*) AS total_fatos,
    COUNT(p.professor_key) AS professores_validos,
    COUNT(d.departamento_key) AS departamentos_validos,
    COUNT(c.curso_key) AS cursos_validos,
    COUNT(dis.disciplina_key) AS disciplinas_validas,
    COUNT(dt.data_key) AS datas_validas
FROM universidade_dw.fato_ensino f
LEFT JOIN universidade_dw.dim_professor p
    ON p.professor_key = f.professor_key
LEFT JOIN universidade_dw.dim_departamento d
    ON d.departamento_key = f.departamento_key
LEFT JOIN universidade_dw.dim_curso c
    ON c.curso_key = f.curso_key
LEFT JOIN universidade_dw.dim_disciplina dis
    ON dis.disciplina_key = f.disciplina_key
LEFT JOIN universidade_dw.dim_data dt
    ON dt.data_key = f.data_key;

SELECT
    COUNT(*) AS quantidade_registros,
    SUM(carga_horaria) AS total_horas,
    MIN(carga_horaria) AS menor_carga,
    MAX(carga_horaria) AS maior_carga
FROM universidade_dw.fato_ensino;

-- Auditoria do grão: resultado esperado = zero linhas.
SELECT
    professor_key,
    departamento_key,
    curso_key,
    disciplina_key,
    data_key,
    COUNT(*) AS quantidade
FROM universidade_dw.fato_ensino
GROUP BY
    professor_key,
    departamento_key,
    curso_key,
    disciplina_key,
    data_key
HAVING COUNT(*) > 1;

-- =========================================================
-- 10. CONSULTAS ANALÍTICAS
-- =========================================================

-- 10.1 Total de horas por professor
SELECT
    p.nome_professor,
    COUNT(*) AS quantidade_ofertas,
    SUM(f.carga_horaria) AS total_horas,
    ROUND(AVG(f.carga_horaria), 2) AS media_horas
FROM universidade_dw.fato_ensino f
JOIN universidade_dw.dim_professor p
    ON p.professor_key = f.professor_key
GROUP BY p.nome_professor
ORDER BY total_horas DESC;

-- 10.2 Total de horas por departamento
SELECT
    d.nome_departamento,
    SUM(f.carga_horaria) AS total_horas
FROM universidade_dw.fato_ensino f
JOIN universidade_dw.dim_departamento d
    ON d.departamento_key = f.departamento_key
GROUP BY d.nome_departamento
ORDER BY total_horas DESC;

-- 10.3 Total de horas por curso
SELECT
    c.nome_curso,
    SUM(f.carga_horaria) AS total_horas
FROM universidade_dw.fato_ensino f
JOIN universidade_dw.dim_curso c
    ON c.curso_key = f.curso_key
GROUP BY c.nome_curso
ORDER BY total_horas DESC;

-- 10.4 Análise multidimensional
SELECT
    p.nome_professor,
    d.nome_departamento,
    c.nome_curso,
    dis.nome_disciplina,
    dt.ano,
    dt.mes,
    dt.nome_mes,
    SUM(f.carga_horaria) AS total_horas
FROM universidade_dw.fato_ensino f
JOIN universidade_dw.dim_professor p
    ON p.professor_key = f.professor_key
JOIN universidade_dw.dim_departamento d
    ON d.departamento_key = f.departamento_key
JOIN universidade_dw.dim_curso c
    ON c.curso_key = f.curso_key
JOIN universidade_dw.dim_disciplina dis
    ON dis.disciplina_key = f.disciplina_key
JOIN universidade_dw.dim_data dt
    ON dt.data_key = f.data_key
GROUP BY
    p.nome_professor,
    d.nome_departamento,
    c.nome_curso,
    dis.nome_disciplina,
    dt.ano,
    dt.mes,
    dt.nome_mes
ORDER BY
    dt.ano,
    dt.mes,
    p.nome_professor;

-- 10.5 Análise temporal
SELECT
    dt.ano,
    dt.mes,
    dt.nome_mes,
    COUNT(*) AS quantidade_ofertas,
    SUM(f.carga_horaria) AS total_horas,
    ROUND(AVG(f.carga_horaria), 2) AS media_horas
FROM universidade_dw.fato_ensino f
JOIN universidade_dw.dim_data dt
    ON dt.data_key = f.data_key
GROUP BY
    dt.ano,
    dt.mes,
    dt.nome_mes
ORDER BY
    dt.ano,
    dt.mes;

-- =========================================================
-- 11. VISÃO FINAL DO STAR SCHEMA
-- =========================================================

SELECT
    f.fato_ensino_key,
    p.nome_professor,
    d.nome_departamento,
    d.campus,
    c.nome_curso,
    dis.nome_disciplina,
    dt.data,
    dt.ano,
    dt.nome_mes,
    f.carga_horaria
FROM universidade_dw.fato_ensino f
JOIN universidade_dw.dim_professor p
    ON p.professor_key = f.professor_key
JOIN universidade_dw.dim_departamento d
    ON d.departamento_key = f.departamento_key
JOIN universidade_dw.dim_curso c
    ON c.curso_key = f.curso_key
JOIN universidade_dw.dim_disciplina dis
    ON dis.disciplina_key = f.disciplina_key
JOIN universidade_dw.dim_data dt
    ON dt.data_key = f.data_key
ORDER BY
    dt.data,
    p.nome_professor;
