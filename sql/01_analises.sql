-- Query 1 — Taxa geral de aprovação
-- PERGUNTA: Qual é a taxa de aprovação e reprovação geral?

/* RESULTADO: A análise indica que a taxa geral de aprovação corresponde a 323 alunos (64,6%), enquanto a reprovação totaliza 
177 alunos (35,4%) */ 

SELECT
    passed AS resultado
    , COUNT(*) AS total_alunos
    , ROUND(COUNT(*) * 100.0 / 500, 1) AS percentual
FROM student_performance
GROUP BY passed
ORDER BY passed DESC;

-- Query 2 — Perfil médio dos grupos
-- PERGUNTA: Qual o perfil médio de aprovados vs reprovados?

/* RESULTADO: Alunos aprovados (323) apresentam, em média, maior dedicação (19,5h de estudo), maior frequência (77,9%) e melhor desempenho 
(nota final 65) em comparação aos reprovados (177), que registram 7,7h de estudo, 73,5% de frequência e nota final 39,5 */

SELECT
    passed AS resultado
    , ROUND(AVG(study_hours_per_week), 1) AS media_horas_estudo
    , ROUND(AVG(attendance_rate), 1) AS media_frequencia
    , ROUND(AVG(previous_score), 1) AS media_nota_anterior
    , ROUND(AVG(final_score), 1) AS media_nota_final
    , COUNT(*) AS total
FROM student_performance
GROUP BY passed
ORDER BY passed DESC;

-- Query 3 — Aprovação por faixa de horas de estudo
-- PERGUNTA: A partir de quantas horas semanais a aprovação dispara?

/* RESULTADO: A taxa de aprovação aumenta progressivamente conforme as horas de estudo, saindo de 18,8% (0–5h) até 100% (26–30h), evidenciando 
forte relação entre dedicação e sucesso acadêmico */

SELECT
    CASE
        WHEN study_hours_per_week BETWEEN 0  AND 5  THEN '01 - 0 a 5h'
        WHEN study_hours_per_week BETWEEN 6  AND 10 THEN '02 - 6 a 10h'
        WHEN study_hours_per_week BETWEEN 11 AND 15 THEN '03 - 11 a 15h'
        WHEN study_hours_per_week BETWEEN 16 AND 20 THEN '04 - 16 a 20h'
        WHEN study_hours_per_week BETWEEN 21 AND 25 THEN '05 - 21 a 25h'
        WHEN study_hours_per_week BETWEEN 26 AND 30 THEN '06 - 26 a 30h'
    END                                                  AS faixa_horas,
    COUNT(*)                                             AS total_alunos,
    SUM(CASE WHEN passed = 'Yes' THEN 1 ELSE 0 END)      AS aprovados,
    ROUND(
        SUM(CASE WHEN passed = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                    AS pct_aprovacao
FROM student_performance
GROUP BY faixa_horas
ORDER BY faixa_horas;

-- Query 4 — Evolução de nota individual
-- PERGUNTA: Quantos alunos melhoraram, mantiveram ou pioraram a nota?

/* RESULTADO: A maioria dos alunos apresentou piora no desempenho (308 alunos – 61,6%), enquanto 184 (36,8%) melhoraram e apenas 8 (1,6%) 
mantiveram estabilidade */

SELECT
    CASE
        WHEN final_score > previous_score  THEN 'Melhorou'
        WHEN final_score = previous_score  THEN 'Manteve'
        WHEN final_score < previous_score  THEN 'Piorou'
    END                                        AS evolucao,
    COUNT(*)                                   AS total_alunos,
    ROUND(COUNT(*) * 100.0 / 500, 1)           AS percentual
FROM student_performance
GROUP BY evolucao
ORDER BY total_alunos DESC;

-- Query 5 — Aprovação por escolaridade dos pais
-- PERGUNTA: A escolaridade dos pais influencia o resultado dos filhos?

/* RESULTADO: As taxas de aprovação variam entre 53,6% e 70,5% conforme a escolaridade dos pais, sem padrão linear claro, indicando baixo impacto 
direto dessa variável no desempenho */

SELECT
    parent_education                                          AS escolaridade_pais,
    COUNT(*)                                                  AS total_alunos,
    SUM(CASE WHEN passed = 'Yes' THEN 1 ELSE 0 END)           AS aprovados,
    ROUND(
        SUM(CASE WHEN passed = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                         AS pct_aprovacao
FROM student_performance
GROUP BY parent_education
ORDER BY pct_aprovacao DESC;

-- Query 6 — Alunos em risco crítico
-- PERGUNTA: Quais alunos têm o perfil de maior risco de reprovação?

/* RESULTADO: Alunos em risco de reprovação apresentam padrão de baixa carga de estudo (2 a 9h), frequência reduzida (~54% a 65%) e notas finais 
muito baixas (21 a 38 pontos) */

SELECT
    student_id
    , study_hours_per_week   AS horas_estudo
    , attendance_rate        AS frequencia
    , previous_score         AS nota_anterior
    , final_score            AS nota_final
    , passed                 AS resultado
FROM student_performance
WHERE
    study_hours_per_week < 10
    AND attendance_rate  < 65
    AND previous_score   < 50
ORDER BY final_score ASC;

-- Query 7 —  Ranking com window function
-- PERGUNTA:  Quem são os top 5 alunos por nota final dentro de cada gênero?

/* RESULTADO: Alunos com melhor desempenho apresentam altas notas (85 a 95), associadas a elevada carga de estudo (24 a 30h) e alta frequência 
(majoritariamente acima de 90%) */ 

WITH ranking AS ( 
    SELECT
        student_id,
        gender,
        final_score,
        study_hours_per_week,
        attendance_rate,
        RANK() OVER (
            PARTITION BY gender
            ORDER BY final_score DESC
        ) AS posicao
    FROM student_performance
)
SELECT *
FROM ranking
WHERE posicao <= 5
ORDER BY gender, posicao;

-- Query 8 —  Análise cruzada com CTE
-- PERGUNTA:  Ter internet e fazer extracurricular combinados muda o resultado?

/* RESULTADO: A taxa de aprovação varia pouco entre os perfis (61,7% a 66,4%), indicando que acesso à internet e atividades extracurriculares 
têm impacto limitado no desempenho */

WITH combinacoes AS (
    SELECT
        internet_access || ' internet / ' ||
        extracurricular || ' extracurr.'   AS perfil,
        COUNT(*)                           AS total,
        SUM(CASE WHEN passed = 'Yes' THEN 1 ELSE 0 END) AS aprovados
    FROM student_performance
    GROUP BY internet_access, extracurricular
)
SELECT
    perfil,
    total,
    aprovados,
    ROUND(aprovados * 100.0 / total, 1)    AS pct_aprovacao
FROM combinacoes
ORDER BY pct_aprovacao DESC;
