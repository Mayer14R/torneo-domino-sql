
-- =============================================
-- 1. DROPS PREVENTIVOS (SI EXISTEN)
-- =============================================

-- TABLAS
IF OBJECT_ID('Participacion', 'U') IS NOT NULL DROP TABLE Participacion;
IF OBJECT_ID('Resultado', 'U') IS NOT NULL DROP TABLE Resultado;
IF OBJECT_ID('Partida', 'U') IS NOT NULL DROP TABLE Partida;
IF OBJECT_ID('Inscripcion', 'U') IS NOT NULL DROP TABLE Inscripcion;
IF OBJECT_ID('Torneo', 'U') IS NOT NULL DROP TABLE Torneo;
IF OBJECT_ID('Jugador', 'U') IS NOT NULL DROP TABLE Jugador;
GO

-- VISTAS
IF OBJECT_ID('Vista_InscripcionesConfirmadas', 'V') IS NOT NULL DROP VIEW Vista_InscripcionesConfirmadas;
IF OBJECT_ID('Vista_ParticipacionPorPartida', 'V') IS NOT NULL DROP VIEW Vista_ParticipacionPorPartida;
IF OBJECT_ID('Vista_ResultadosFinales', 'V') IS NOT NULL DROP VIEW Vista_ResultadosFinales;
GO

-- PROCEDIMIENTOS
IF OBJECT_ID('sp_RegistrarInscripcion', 'P') IS NOT NULL DROP PROCEDURE sp_RegistrarInscripcion;
IF OBJECT_ID('sp_ConfirmarInscripcion', 'P') IS NOT NULL DROP PROCEDURE sp_ConfirmarInscripcion;
IF OBJECT_ID('sp_AgregarPartida', 'P') IS NOT NULL DROP PROCEDURE sp_AgregarPartida;
IF OBJECT_ID('sp_RegistrarParticipacion', 'P') IS NOT NULL DROP PROCEDURE sp_RegistrarParticipacion;
IF OBJECT_ID('sp_GenerarResultadosTorneo', 'P') IS NOT NULL DROP PROCEDURE sp_GenerarResultadosTorneo;
GO

-- FUNCIONES
IF OBJECT_ID('fn_TotalParticipantesConfirmados', 'FN') IS NOT NULL DROP FUNCTION fn_TotalParticipantesConfirmados;
IF OBJECT_ID('fn_PromedioPuntajeJugador', 'FN') IS NOT NULL DROP FUNCTION fn_PromedioPuntajeJugador;
IF OBJECT_ID('fn_PuntosPorJugadorEnTorneo', 'IF') IS NOT NULL DROP FUNCTION fn_PuntosPorJugadorEnTorneo;
GO

-- =============================================
-- 2. CREACIÓN DE TABLAS (DDL)
-- =============================================

CREATE TABLE Jugador (
    ID_Jugador INT PRIMARY KEY IDENTITY(1,1),
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    Edad INT NOT NULL,
    Nivel VARCHAR(20) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Telefono VARCHAR(20) NULL
);
GO

CREATE TABLE Torneo (
    ID_Torneo INT PRIMARY KEY IDENTITY(1,1),
    NombreTorneo VARCHAR(100) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Lugar VARCHAR(100) NOT NULL
);
GO

CREATE TABLE Inscripcion (
    ID_Inscripcion INT PRIMARY KEY IDENTITY(1,1),
    ID_Jugador INT NOT NULL,
    ID_Torneo INT NOT NULL,
    FechaInscripcion DATETIME NOT NULL,
    Confirmado VARCHAR(2) NOT NULL,
    FOREIGN KEY (ID_Jugador) REFERENCES Jugador(ID_Jugador),
    FOREIGN KEY (ID_Torneo) REFERENCES Torneo(ID_Torneo)
);
GO

CREATE TABLE Partida (
    ID_Partida INT PRIMARY KEY IDENTITY(1,1),
    ID_Torneo INT NOT NULL,
    FechaHora DATETIME NOT NULL,
    Ronda INT NOT NULL,
    FOREIGN KEY (ID_Torneo) REFERENCES Torneo(ID_Torneo)
);
GO

CREATE TABLE Participacion (
    ID_Partida INT NOT NULL,
    ID_Jugador INT NOT NULL,
    Puntaje INT NOT NULL,
    PRIMARY KEY (ID_Partida, ID_Jugador),
    FOREIGN KEY (ID_Partida) REFERENCES Partida(ID_Partida),
    FOREIGN KEY (ID_Jugador) REFERENCES Jugador(ID_Jugador)
);
GO

CREATE TABLE Resultado (
    ID_Resultado INT PRIMARY KEY IDENTITY(1,1),
    ID_Jugador INT NOT NULL,
    ID_Torneo INT NOT NULL,
    Posicion INT NOT NULL,
    TotalPuntos INT NOT NULL,
    FOREIGN KEY (ID_Jugador) REFERENCES Jugador(ID_Jugador),
    FOREIGN KEY (ID_Torneo) REFERENCES Torneo(ID_Torneo)
);
GO

-- =============================================
-- 3. VISTAS (SIN ORDER BY)
-- =============================================

CREATE VIEW Vista_InscripcionesConfirmadas AS
SELECT 
    i.ID_Inscripcion,
    j.Nombre + ' ' + j.Apellido AS NombreCompleto,
    j.Nivel,
    t.NombreTorneo,
    i.FechaInscripcion
FROM Inscripcion i
JOIN Jugador j ON i.ID_Jugador = j.ID_Jugador
JOIN Torneo t ON i.ID_Torneo = t.ID_Torneo
WHERE i.Confirmado = 'Sí';
GO

CREATE VIEW Vista_ParticipacionPorPartida AS
SELECT 
    pr.ID_Partida,
    pa.FechaHora,
    pa.Ronda,
    j.Nombre + ' ' + j.Apellido AS NombreJugador,
    pr.Puntaje
FROM Participacion pr
JOIN Jugador j ON pr.ID_Jugador = j.ID_Jugador
JOIN Partida pa ON pr.ID_Partida = pa.ID_Partida;
GO

CREATE VIEW Vista_ResultadosFinales AS
SELECT 
    r.ID_Resultado,
    j.Nombre + ' ' + j.Apellido AS NombreJugador,
    t.NombreTorneo,
    r.TotalPuntos,
    r.Posicion
FROM Resultado r
JOIN Jugador j ON r.ID_Jugador = j.ID_Jugador
JOIN Torneo t ON r.ID_Torneo = t.ID_Torneo;
GO

-- =============================================
-- 4. PROCEDIMIENTOS
-- =============================================

CREATE PROCEDURE sp_RegistrarInscripcion
  @JugadorID       INT,
  @TorneoID        INT,
  @FechaInscripcion DATETIME
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO Inscripcion (
    ID_Jugador, ID_Torneo, FechaInscripcion, Confirmado
  )
  VALUES (
    @JugadorID, @TorneoID, @FechaInscripcion, 'No'
  );
  SELECT SCOPE_IDENTITY() AS NuevoID_Inscripcion;
END;
GO

CREATE PROCEDURE sp_ConfirmarInscripcion
  @InscripcionID INT
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE Inscripcion
  SET Confirmado = 'Sí'
  WHERE ID_Inscripcion = @InscripcionID;
END;
GO

CREATE PROCEDURE sp_AgregarPartida
  @TorneoID  INT,
  @FechaHora DATETIME,
  @Ronda     INT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO Partida (
    ID_Torneo, FechaHora, Ronda
  )
  VALUES (
    @TorneoID, @FechaHora, @Ronda
  );
  SELECT SCOPE_IDENTITY() AS NuevoID_Partida;
END;
GO

CREATE PROCEDURE sp_RegistrarParticipacion
  @PartidaID INT,
  @JugadorID INT,
  @Puntaje   INT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO Participacion (
    ID_Partida, ID_Jugador, Puntaje
  )
  VALUES (
    @PartidaID, @JugadorID, @Puntaje
  );
END;
GO

CREATE PROCEDURE sp_GenerarResultadosTorneo
  @TorneoID INT
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM Resultado
  WHERE ID_Torneo = @TorneoID;

  ;WITH Totales AS (
    SELECT
      pr.ID_Jugador,
      SUM(pr.Puntaje) AS TotalPuntos
    FROM Participacion pr
    JOIN Partida p ON pr.ID_Partida = p.ID_Partida
    WHERE p.ID_Torneo = @TorneoID
    GROUP BY pr.ID_Jugador
  ),
  Rankings AS (
    SELECT
      t.ID_Jugador,
      t.TotalPuntos,
      RANK() OVER (ORDER BY t.TotalPuntos DESC) AS Posicion
    FROM Totales t
  )
  INSERT INTO Resultado (
    ID_Jugador, ID_Torneo, TotalPuntos, Posicion
  )
  SELECT
    r.ID_Jugador,
    @TorneoID,
    r.TotalPuntos,
    r.Posicion
  FROM Rankings r;
END;
GO

-- =============================================
-- 5. FUNCIONES
-- =============================================

CREATE FUNCTION fn_TotalParticipantesConfirmados
(
  @TorneoID INT
)
RETURNS INT
AS
BEGIN
  DECLARE @Total INT;
  SELECT 
    @Total = COUNT(DISTINCT i.ID_Jugador)
  FROM Inscripcion i
  WHERE i.ID_Torneo = @TorneoID
    AND i.Confirmado = 'Sí';
  RETURN ISNULL(@Total, 0);
END;
GO

CREATE FUNCTION fn_PromedioPuntajeJugador
(
  @JugadorID INT,
  @TorneoID  INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
  DECLARE @Promedio DECIMAL(10,2);
  SELECT 
    @Promedio = AVG(CONVERT(DECIMAL(10,2), pr.Puntaje))
  FROM Participacion pr
  JOIN Partida p ON pr.ID_Partida = p.ID_Partida
  WHERE pr.ID_Jugador = @JugadorID
    AND p.ID_Torneo = @TorneoID;
  RETURN ISNULL(@Promedio, 0.00);
END;
GO

CREATE FUNCTION fn_PuntosPorJugadorEnTorneo
(
  @TorneoID INT
)
RETURNS TABLE
AS
RETURN
(
  SELECT
    j.ID_Jugador,
    j.Nombre + ' ' + j.Apellido AS NombreJugador,
    SUM(pr.Puntaje) AS TotalPuntos
  FROM Participacion pr
  JOIN Partida p ON pr.ID_Partida = p.ID_Partida
  JOIN Jugador j ON pr.ID_Jugador = j.ID_Jugador
  WHERE p.ID_Torneo = @TorneoID
  GROUP BY j.ID_Jugador, j.Nombre, j.Apellido
);
GO
