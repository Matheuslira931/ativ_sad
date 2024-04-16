# Criando banco de dados
CREATE DATABASE atividade_sad;
USE atividade_sad;

# Criando tabela Vendas
CREATE TABLE Vendas (
    VendaID INT AUTO_INCREMENT PRIMARY KEY,
    DataVenda DATETIME,
    ValorVenda DECIMAL(10, 2),
    ClienteID INT,
    NomeCliente VARCHAR(100),
    EnderecoCliente VARCHAR(255),
    ProdutoID INT,
    NomeProduto VARCHAR(100),
    PrecoUnitario DECIMAL(10, 2),
    Quantidade INT,
    VendedorID INT,
    NomeVendedor VARCHAR(100)
);

# Colocando dados na Tabela Vendas
DELIMITER //
CREATE PROCEDURE criarRegistrosVendas (qtdRegistros TINYINT UNSIGNED)
BEGIN
DECLARE contador TINYINT UNSIGNED DEFAULT 0;
WHILE contador < qtdRegistros DO
    INSERT INTO Vendas (
        DataVenda,
        ValorVenda,
        ClienteID,
        NomeCliente,
        EnderecoCliente,
        ProdutoID,
        NomeProduto,
        PrecoUnitario,
        Quantidade,
        VendedorID,
        NomeVendedor
    )
    VALUES (
        NOW(),
        ROUND((RAND() * (500 - 50) + 50), 2),
        contador % 10 + 1,
        CONCAT('Cliente ', CAST((contador % 10 + 1) AS CHAR)),
        CONCAT('Endereço ', CAST((contador % 10 + 1) AS CHAR)),
        contador % 5 + 1,
        CONCAT('Produto ', CAST((contador % 5 + 1) AS CHAR)),
        ROUND((RAND() * (100 - 10) + 10), 2),
        contador % 3 + 1,
        contador % 4 + 1,
        CONCAT('Vendedor ', CAST((contador % 4 + 1) AS CHAR))
    );

    SET contador = contador + 1;
END WHILE;
END//
DELIMITER ;

-- Testando:
CALL criarRegistrosVendas(200);


# três dimensões: Cliente, Vendedor e Produto

CREATE TABLE DIM_Cliente (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100),
    Endereco VARCHAR(255)
);

CREATE TABLE DIM_Vendedor (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100)
);

CREATE TABLE DIM_Produto (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100),
    Preco DECIMAL(10, 2)
);

CREATE TABLE DIM_Data (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    dataHora DATETIME,
    dataCalendario DATE,
    horas TIME,
    ano INT,
    mes INT,
    dia INT
);

# Colocando dados nas Dimensões
# Cliente
INSERT INTO DIM_Cliente (Nome, Endereco)
SELECT NomeCliente, EnderecoCliente
FROM Vendas
WHERE VendaID IN (SELECT MAX(VendaID) FROM Vendas GROUP BY NomeCliente);

# Produto
INSERT INTO DIM_Produto (Nome, Preco)
SELECT NomeProduto, PrecoUnitario
FROM Vendas
WHERE VendaID IN (SELECT MAX(VendaID) FROM Vendas GROUP BY NomeProduto);

# Vendedor
INSERT INTO DIM_Vendedor (Nome)
SELECT DISTINCT
    NomeVendedor
FROM Vendas;

# Data
INSERT INTO DIM_Data (dataHora, dataCalendario, horas, ano, mes, dia)
SELECT DISTINCT
    DataVenda,
    DATE(DataVenda),
    TIME(DataVenda),
    YEAR(DataVenda),
    MONTH(DataVenda),
    DAY(DataVenda)
FROM Vendas;

# Criando Tabela Fato
CREATE TABLE Venda_Fato (
    VendaID INT AUTO_INCREMENT PRIMARY KEY,
    ClienteID INT,
    ProdutoID INT,
    VendedorID INT,
    DataID INT,
    ValorVenda DECIMAL(10, 2),
    Quantidade INT,
    FOREIGN KEY (ClienteID) REFERENCES DIM_Cliente(ID),
    FOREIGN KEY (ProdutoID) REFERENCES DIM_Produto(ID),
    FOREIGN KEY (VendedorID) REFERENCES DIM_Vendedor(ID),
    FOREIGN KEY (DataID) REFERENCES DIM_Data(ID)
);

# Colocando dados na tabela Fato
INSERT INTO Venda_Fato (ClienteID, ProdutoID, VendedorID, DataID, ValorVenda, Quantidade)
SELECT cliente.ID,
    produto.ID,
    vendedor.ID,
    dataCal.ID,
    Vendas.ValorVenda,
    Vendas.Quantidade
FROM
    Vendas
    INNER JOIN DIM_Data AS dataCal ON Vendas.DataVenda = dataCal.dataHora
    INNER JOIN DIM_Cliente AS cliente ON Vendas.NomeCliente = cliente.Nome
    INNER JOIN DIM_Produto AS produto ON Vendas.NomeProduto = produto.Nome
    INNER JOIN DIM_Vendedor AS vendedor ON Vendas.NomeVendedor = vendedor.Nome;
    
# Exibindo os dados da tabela fato com as dimensões
SELECT
    dataCal.dataCalendario AS DataVenda,
    venda.ValorVenda,
    cliente.Nome AS NomeCliente,
    cliente.Endereco AS EnderecoCliente,
    produto.Nome AS NomeProduto,
    produto.Preco AS PrecoProduto,
    venda.Quantidade,
    vendedor.Nome AS NomeVendedor
FROM
    Venda_Fato AS venda
 INNER JOIN
    DIM_Data AS dataCal ON venda.DataID = dataCal.ID   
INNER JOIN
    DIM_Cliente AS cliente ON venda.ClienteID = cliente.ID
INNER JOIN
    DIM_Produto AS produto ON venda.ProdutoID = produto.ID
INNER JOIN
    DIM_Vendedor AS vendedor ON venda.VendedorID = vendedor.ID;
