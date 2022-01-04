--------------------------------------------------------
-- Archivo creado  - lunes-enero-03-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure PRC_REGISTRARLOGERROR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "BASTIAN_2"."PRC_REGISTRARLOGERROR" 
        (FUNCION IN VARCHAR2, CODE IN VARCHAR2, E_RROR IN VARCHAR2)
    IS
    BEGIN
        INSERT INTO LOGERROR VALUES (SEQ_ERROR_ID.NEXTVAL, FUNCION, CODE, E_RROR, SYSDATE, USER);
END prc_registrarLogError;

--1.2
CREATE OR REPLACE FUNCTION FN_BUSCARCLIENTE
   (V_RUT IN VARCHAR2)
   RETURN NUMBER
IS 
    RUT_CLIENTE VARCHAR2(100);
    ID_CLIENTE NUMBER;
    CODE VARCHAR2(100);
    E_RROR VARCHAR2(500);
BEGIN
   SELECT
        RUT,
        CLIENTE_ID
   INTO
        RUT_CLIENTE,
        ID_CLIENTE
   FROM CLIENTE
   WHERE RUT = V_RUT;
   RETURN ID_CLIENTE;
END FN_BUSCARCLIENTE;

--PACKAGE    
CREATE OR REPLACE PACKAGE PCK_HELADOS AS
    PROCEDURE PRC_GENERARPEDIDO(V_RUT IN VARCHAR2);
    PROCEDURE PRC_AGREGARHELADO(V_HELADO_CODE IN VARCHAR2, V_RUT IN VARCHAR2);
    PROCEDURE PRC_TOTALIZARPEDIDO(V_RUT IN VARCHAR2);
    PROCEDURE PRC_LIMPIATABLA;
END PCK_HELADOS;

CREATE OR REPLACE PACKAGE BODY PCK_HELADOS as    
    PROCEDURE PRC_GENERARPEDIDO(V_RUT IN VARCHAR2) IS
        V_PEDIDOS NUMBER;
        CODE VARCHAR2(100);
        E_RROR VARCHAR2(500);
    BEGIN 
        SELECT
            COUNT(PEDIDO_ID)
        INTO
            V_PEDIDOS
        FROM PEDIDO
        WHERE CLIENTE_ID = FN_BUSCARCLIENTE(V_RUT);  
        IF V_PEDIDOS = 0 THEN
            INSERT INTO PEDIDO VALUES(SEQ_PEDIDO.NEXTVAL, SYSDATE, 'ACTIVO', 0, FN_BUSCARCLIENTE(V_RUT));
        ELSIF V_PEDIDOS > 0 THEN
                UPDATE PEDIDO SET ESTADO = 'CANCELADO'
                WHERE CLIENTE_ID = FN_BUSCARCLIENTE(V_RUT) AND ESTADO = 'ACTIVO';
            INSERT INTO PEDIDO VALUES(SEQ_PEDIDO.NEXTVAL, SYSDATE, 'ACTIVO', 0, FN_BUSCARCLIENTE(V_RUT));
        END IF;
    EXCEPTION WHEN OTHERS THEN
        CODE := SQLCODE;
        E_RROR := SQLERRM;
        EXECUTE IMMEDIATE 'BEGIN PRC_REGISTRARLOGERROR(:A, :B, :C); END;' USING 'PRC_GENERARPEDIDO', CODE, E_RROR;   
    END PRC_GENERARPEDIDO;


    PROCEDURE PRC_AGREGARHELADO(V_HELADO_CODE IN VARCHAR2, V_RUT IN VARCHAR2) IS 
        V_HELADO_ID NUMBER;
        V_PEDIDO_ID NUMBER;
        V_ESTADO VARCHAR2(100);
        V_CANTIDAD NUMBER;
        CODE VARCHAR2(100);
        E_RROR VARCHAR2(100);
    BEGIN
        SELECT
            HELADO_ID
        INTO
            V_HELADO_ID
        FROM HELADO
        WHERE HELADO_CD = V_HELADO_CODE; 
        SELECT
            ESTADO,
            PEDIDO_ID
        INTO
            V_ESTADO,
            V_PEDIDO_ID
        FROM PEDIDO
        WHERE CLIENTE_ID = FN_BUSCARCLIENTE(V_RUT) AND ESTADO = 'ACTIVO';
        SELECT 
            COUNT(HELADO_ID)
        INTO
            V_CANTIDAD
        FROM PEDIDODETALLE
        WHERE PEDIDO_ID = V_PEDIDO_ID;
        IF V_ESTADO = 'ACTIVO' AND V_CANTIDAD = 0 THEN
            INSERT INTO PEDIDODETALLE VALUES(SEQ_PEDIDODETALLE.NEXTVAL, V_PEDIDO_ID, V_HELADO_ID, 1);
        ELSE
            UPDATE PEDIDODETALLE
            SET CANTIDAD = V_CANTIDAD + 1
            WHERE PEDIDO_ID = V_PEDIDO_ID;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        CODE := SQLCODE;
        E_RROR := SQLERRM;
        EXECUTE IMMEDIATE 'BEGIN PRC_REGISTRARLOGERROR(:A, :B, :C); END;' USING 'PRC_GENERARPEDIDO', CODE, E_RROR;    
    END PRC_AGREGARHELADO;

    PROCEDURE PRC_TOTALIZARPEDIDO(V_RUT VARCHAR2) IS 
        V_TOTAL NUMBER := 0;
        V_PEDIDO_ID NUMBER;
        V_PRECIO_BASE NUMBER;
        CODE VARCHAR2(100);
        E_RROR VARCHAR2(100);
    BEGIN
        SELECT 
            PEDIDO_ID
        INTO
            V_PEDIDO_ID
        FROM PEDIDO
        WHERE CLIENTE_ID = FN_BUSCARCLIENTE(V_RUT) AND ESTADO = 'ACTIVO';
        FOR PRODUCTO IN (SELECT HELADO_ID, CANTIDAD FROM PEDIDODETALLE WHERE PEDIDO_ID =V_PEDIDO_ID) 
        LOOP
            SELECT
                PRECIOBASE
            INTO
                V_PRECIO_BASE
            FROM HELADO
            WHERE HELADO_ID = PRODUCTO.HELADO_ID;
            V_TOTAL := V_TOTAL + (PRODUCTO.CANTIDAD * V_PRECIO_BASE);
        END LOOP;
        UPDATE PEDIDO SET VALOR = V_TOTAL, ESTADO = 'VENDIDO' WHERE PEDIDO_ID = V_PEDIDO_ID;
    EXCEPTION WHEN OTHERS THEN
        CODE := SQLCODE;
        E_RROR := SQLERRM;
        EXECUTE IMMEDIATE 'BEGIN PRC_REGISTRARLOGERROR(:A, :C, :B); END;' USING 'PRC_GENERARPEDIDO', CODE, E_RROR;    
    END PRC_TOTALIZARPEDIDO; 

    PROCEDURE PRC_LIMPIATABLA IS
    BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE PEDIDODETALLE CASCADE CONSTRAINT';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE PEDIDO CASCADE CONSTRAINT';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE LOGVENTA CASCADE CONSTRAINT';
    END PRC_LIMPIATABLA;
END PCK_HELADOS;








--ACTIVATE
BEGIN
    PCK_HELADOS.PRC_GENERARPEDIDO('1');
END;

BEGIN
    pck_helados.prc_AgregarHelado('CopaPasion', '1-9');
END;

BEGIN
    pck_helados.prc_TotalizarPedido('1-9');
END;

BEGIN
    pck_helados.prc_LimpiaTabla;
END;

/
