use Northwind
--requirement 1: -	Truy vấn danh sách các Customer 
select *
from Customer
--requirement 2: -	Truy vấn danh sách các Customer theo các thông tin Id, FullName (là kết hợp FirstName-LastName), City, Country ???
--cách 1
select Id, 
       CONCAT(FirstName,' ',LastName) as FullName,
	   City,Country
from Customer

--cách 2
select Id, 
       CONCAT(LEFT(FirstName,case when CHARINDEX(' ',FirstName)=0 then lEN(FirstName)
	   else CHARINDEX(' ',FirstName)-1 end),' ',
	   SUBSTRING(LastName,CHARINDEX(' ',LastName) +1,100)) as FullName,
	   City,Country
from Customer

--requirement 3: - 	Cho biết có bao nhiêu khách hàng từ Germany và UK, đó là những khách hàng nào
select CONCAT(LEFT(FirstName,case when CHARINDEX(' ',FirstName)=0 then lEN(FirstName)
	   else CHARINDEX(' ',FirstName)-1 end),' ',
	   SUBSTRING(LastName,CHARINDEX(' ',LastName) +1,100)) as FullName
from Customer
where Country in('Germany','UK') 
group by Country,FirstName,LastName

--requirement 4:-	Liệt kê danh sách khách hàng theo thứ tự tăng dần của FirstName và giảm dần của Country
select *
from Customer
order by FirstName ASC, Country DESC

--requirement 5: -	Truy vấn danh sách các khách hàng với ID là 5,10, từ 1-10, và từ 5-10
--5,10
select *
from Customer
where Id in ('3','5')
--1-10
select top 10*
from Customer
--5-10
select *
from Customer
order by Id ASC
Offset 4 Rows 
Fetch next 6 rows only

--requirement 6: -	Truy vấn các khách hàng ở các sản phẩm (Product) mà đóng gói dưới dạng bottles có giá từ 15 đến 20 mà không từ nhà cung cấp có ID là 16. 
select P.Id, CONCAT(LEFT(FirstName,case when CHARINDEX(' ',FirstName)=0 then lEN(FirstName)
	   else CHARINDEX(' ',FirstName)-1 end),' ',
	   SUBSTRING(LastName,CHARINDEX(' ',LastName) +1,100)) as FullName,
       P.ProductName,P.UnitPrice,P.Package
from Customer as C, Product as P
where C.Id=P.Id and not P.Id=16 and P.Package like '%bottles%' and P.UnitPrice between 15 and 20 

---	Xuất danh sách các nhà cung cấp (gồm Id, CompanyName, ContactName, City, Country, Phone) 
--kèm theo giá min và max của các sản phẩm mà nhà cung cấp đó cung cấp.
--Có sắp xếp theo thứ tự Id của nhà cung cấp
select S.Id,S.CompanyName,S.ContactName,S.City,S.Country,S.Phone, 
       MIN(P.UnitPrice) as [Giá nhỏ nhât],
	   MAX(P.UnitPrice) as [Gía lớn nhất]
from Supplier as S
INNER JOIN [Product] as P on S.Id=P.SupplierId
group by S.Id,S.CompanyName,S.ContactName,S.City,S.Country,S.Phone
order by S.Id DESC

---	Cũng câu trên nhưng chỉ xuất danh sách nhà cung cấp có sự khác biệt giá (max – min) không quá lớn (<=30).
select S.Id,S.CompanyName,S.ContactName,S.City,S.Country,S.Phone, 
       MIN(P.UnitPrice) as [Giá nhỏ nhât],
	   MAX(P.UnitPrice) as [Gía lớn nhất]
from Supplier as S
INNER JOIN [Product] as P on S.Id=P.SupplierId
group by S.Id,S.CompanyName,S.ContactName,S.City,S.Country,S.Phone
having  MAX(P.UnitPrice) <=30 and MIN(P.UnitPrice)<=30 
order by S.Id DESC

---	Xuất danh sách các hóa đơn (Id, OrderNumber, OrderDate) kèm theo tổng giá chi trả (UnitPrice*Quantity) cho hóa đơn đó, 
--bên cạnh đó có cột Description là “VIP” nếu tổng giá lớn hơn 1500 và “Normal” nếu tổng giá nhỏ hơn 1500(Gợi ý: Dùng UNION)
select O.Id, O.OrderNumber, O.OrderDate, OI.UnitPrice*OI.Quantity as [Tổng giá chi trả], 'VIP' As [Description]
from [Order] as O
INNER JOIN [OrderItem]as OI on O.Id=OI.OrderId
where OI.UnitPrice*OI.Quantity >1500
select O.Id, O.OrderNumber, O.OrderDate, OI.UnitPrice*OI.Quantity as [Tổng giá chi trả], 'Normal' As [Description]
from [Order] as O
INNER JOIN [OrderItem]as OI on O.Id=OI.OrderId
where OI.UnitPrice*OI.Quantity <1500

---	Xuất danh sách những hóa đơn (Id, OrderNumber, OrderDate) trong tháng 7 nhưng phải ngoại trừ ra những hóa đơn từ khách hàng France. 
-- Xuất thêm cột họ tên và Country
select O.Id,O.OrderNumber,O.OrderDate, C.FirstName +' '+ C.LastName as [Fullname], C.Country
from [Order] as O
INNER JOIN [Customer]as C on O.CustomerId=C.Id
where MONTH(OrderDate) =07
EXCEPT
select O.Id,O.OrderNumber,O.OrderDate, C.FirstName +' '+ C.LastName as [Fullname],C.Country
from [Customer] as C
INNER JOIN [Order]as O on O.CustomerId=C.Id
where Country like 'France'

---	Xuất danh sách những hóa đơn (Id, OrderNumber, OrderDate, TotalAmount)  nào có TotalAmount nằm trong top 5 các hóa đơn. 
select Id,OrderNumber,OrderDate, TotalAmount
from [Order]
where TotalAmount IN (Select top 5 TotalAmount from [Order] order by TotalAmount DESC )

---	Sắp xếp sản phẩm tăng dần theo UnitPrice, và tìm 20% dòng có UnitPrice cao nhất
select *
from
( 
   select RowNum, Id,OrderId,ProductId,Max(RowNum) over (Order by (select 2)) as Rowlast
   from (
       select ROW_NUMBER() over (order by Quantity) as RowNum,
	   Id,OrderId,ProductId
       from OrderItem
   ) As DerivedTable
) Report, Product as P
where Report.RowNum >= 0.2*Rowlast and P.Id=Report.ProductId

--- Xuất danh sách các nhà cung cấp kèm theo các cột USA, UK, France, Germany, Others. 
---Nếu nhà cung cấp nào thuộc các quốc gia  này thì ta đánh số 1 còn lại là 0 
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME=N'F')
begin 
    TRUNCATE TABLE F
END

 SELECT ContactName,(CASE 
	      When Country like 'Japan' then 'Others'
		  When Country like 'Spain' then 'Others'
		  When Country like 'Australia' then 'Others'
		  When Country like 'Italy' then 'Others'
		  When Country like 'Norway' then 'Others'
		  When Country like 'Sweden' then 'Others'
		  When Country like 'Singapore' then 'Others'
		  When Country like 'Denmark' then 'Others'
		  When Country like 'Netherlands' then 'Others'
		  When Country like 'Finland' then 'Others'
		  When Country like 'Canada' then 'Others'
		  When Country like 'UK' then 'UK'
		  When Country like 'USA' then 'USA'
		  When Country like 'Germany' then 'Germany'
		  When Country like 'France' then 'France'
		  When Country like 'Brazil' then 'Others'
	  End) as SupplierCountry
INTO F
from [Supplier]
  
select *
FROM 
(SELECT ContactName, SupplierCountry, (CASE 
	      When SupplierCountry like 'Others' then '0'
		  When SupplierCountry like 'USA' then '1'
		  When SupplierCountry like 'UK' then '1'
		  When SupplierCountry like 'Germany' then '1'
		  When SupplierCountry like 'France' then '1'
	  End) as [Request] 
 FROM F
)AS SOURCE_TABLE
PIVOT 
(
  Max(SupplierCountry) FOR Request in ([0],[1])
) as B

---	Xuất danh sách các hóa đơn gồm OrderNumber, OrderDate (format: dd mm yyyy), 
--CustomerName, Address (format: “Phone: …… , City: …. and Country: ….”),
--TotalAmount làm tròn không chữ số thập phân và đơn vị theo kèm là Euro) 
select OrderNumber,
       OrderDate=CONVERT(varchar(10),O.OrderDate,104),
       C.FirstName +' '+C.LastName as CustomerName,
	   Address='Phone' + ':' + SPACE(1)+ C.Phone + ',' +SPACE(1) + 'City' +':'+ SPACE(1)+C.City+SPACE(1)+ 'and' 
	   +SPACE(1)+'Country'+':'+SPACE(1)+C.Country,
	   TotalAmount=LTRIM(STR(CAST(O.TotalAmount AS DECIMAL(10,0)),10,1)+SPACE(1)+'EUR')
from [Order] O
INNER JOIN [Customer] as C ON O.CustomerId=C.Id


----	Xuất danh sách các sản phẩm dưới dạng đóng gói bags. Thay đổi chữ bags thành ‘túi’
select Id, ProductName, SupplierId, UnitPrice, 
       Package=STUFF(Package,CHARINDEX('bags',Package), len('bags'),N'Túi')
from Product
where Package like '%bags%'


----	Xuất danh sách các khách hàng theo tổng số hóa đơn mà khách hàng đó có, sắp xếp theo thứ tự giảm dần của tổng số hóa đơn,  
--kèm theo đó là  các thông tin phân hạng DENSE_RANK và nhóm (chia thành 3 nhóm) (Gợi ý: dùng NTILE(3) để chia nhóm. 
select OrderNumber,
       OrderDate=CONVERT(varchar(10),O.OrderDate,104),
       C.FirstName +' '+C.LastName as CustomerName,
	   Address='Phone' + ':' + SPACE(1)+ C.Phone + ',' +SPACE(1) + 'City' +':'+ SPACE(1)+C.City+SPACE(1)+ 'and' 
	   +SPACE(1)+'Country'+':'+SPACE(1)+C.Country,
	   [Rank]=DENSE_RANK() over (order by TotalAmount),
	   NTILE(3) OVER(
		ORDER BY TotalAmount DESC
	) [group]
from [Order] O
INNER JOIN [Customer] as C ON O.CustomerId=C.Id
order by TotalAmount DESC 

---2.	Xuất các hóa đơn kèm theo thông tin ngày trong tuần của hóa đơn là : Thứ 2, 3,4,5,6,7, Chủ Nhật
SELECT *,DATENAME(dw, OrderDate) AS [Day Name]
FROM [Order]


---3.	Với mỗi ProductID trong OrderItem xuất các thông tin gồm OrderID, ProductID, ProductName, UnitPrice, Quantity, ContactInfo, ContactType. 
--Trong đó ContactInfo ưu tiên Fax, nếu không thì dùng Phone của Supplier sản phẩm đó. Còn ContactType là ghi chú đó là loại ContactInfo nào
select O.OrderId,O.ProductId,P.ProductName,P.UnitPrice,O.Quantity,
       COALESCE(Fax,Phone) as ContactInfo,
	   Case COALESCE(Fax,Phone) when Fax then 'Fax' else 'Phone' end as ContactType
from [Supplier] S, [OrderItem] O
INNER JOIN [Product] P ON O.ProductId=P.Id

---4.	Cho biết Id của database Northwind, Id của bảng Supplier, Id của User mà bạn đang đăng nhập là bao nhiêu. 
--Cho biết luôn tên User mà đang đăng nhập


---5.	Cho biết các thông tin user_update, user_seek, user_scan và user_lookup trên bảng Order trong database Northwind


---6.	Dùng WITH phân chia cây như sau : Mức 0 là các Quốc Gia(Country), mức 1 là các Thành Phố (City) thuộc Country đó, 
--và mức 2 là các Hóa Đơn (Order) thuộc khách hàng từ Country-City đó
WITH SupplierCategory(Country,City,Id,alevel)
AS(
   SELECT DISTINCT Country,
   City=CAST('' AS nvarchar(255)),
   Id=CAST('' AS varchar(255)),
   alevel=0
   from Supplier

   UNION ALL 

   SELECT S.Country,
   City=CAST(S.City AS nvarchar(255)),
   Id=CAST('' AS varchar(255)),
   alevel=SC.alevel+1
   from SupplierCategory as SC 
   INNER JOIN Supplier S ON SC.Country=S.Country
   where SC.alevel=0

   UNION ALL 

   SELECT S.Country,
   City=CAST(S.City AS nvarchar(255)),
   Id=CAST(S.Id AS varchar(255)),
   alevel=SC.alevel+1
   from SupplierCategory as SC 
   INNER JOIN Supplier S ON SC.Country=S.Country and SC.City=S.Country
   where SC.alevel=1
)
select [Quoc Gia]= case when alevel=0 then Country else '--'end,
       [Thanh Pho]= case when alevel=1 then City else '--'end,
	   [Hoa Don]= Id,
	   Cap=alevel
from SupplierCategory
order by Country, City,Id,alevel



---7.	Xuất những hóa đơn từ khách hàng France mà có tổng số lượng Quantity lớn hơn 50 của các sản phẩm thuộc hóa đơn ấy 
WITH QuantityFill AS
(
     SELECT OI.Quantity
	 FROM [OrderItem] OI
	 INNER JOIN [Order] O ON O.Id=OI.OrderId
	 where OI.Quantity > 50
),
CustomerFromFrance AS
(     
     SELECT C.*
	 FROM Customer as C
	 INNER JOIN [Order] O ON O.CustomerId=C.Id
	 WHERE Country='France'
)
select *
from CustomerFromFrance, QuantityFill as Q


--- 1. Tạo view
--o	uvw_DetailProductInOrder với các cột sau OrderId, OrderNumber, OrderDate, ProductId,
--ProductInfo ( = ProductName + Package. Ví dụ: Chai 10 boxes x 20 bags), UnitPrice và Quantity
CREATE VIEW uvw_DetailProductInOrder
AS
   SELECT OI.OrderId,O.OrderNumber,O.OrderDate,OI.ProductId,
          ProductInfo=P.ProductName + SPACE(1) + P.Package,
		  OI.UnitPrice,OI.Quantity
   FROM [Order] O, [Product] P,[OrderItem] as OI 
   Where OI.OrderId=O.Id and OI.ProductId=P.Id
Go
select * from uvw_DetailProductInOrder


--o	uvw_AllProductInOrder với các cột sau OrderId, OrderNumber, OrderDate,    OI.OrderId,
--ProductList (ví dụ “11,42,72” với OrderId 1), và TotalAmount ( = SUM(UnitPrice * Quantity)) theo mỗi OrderId  	
--(Gợi ý dùng FOR XML PATH để tạo cột ProductList)
create view uvw_AllProductInOrder
as
	select D.OrderId, D.OrderNumber, D.OrderDate,
		   SUBSTRING
		   (	
		     (
				select ','+ CONVERT(nvarchar(10), OI.ProductId )
				from OrderItem as OI
				where OI.OrderId= D.OrderId
				for xml path('')
			 ),2,1000
		   )ProductList,
				sum( D.UnitPrice* D.Quantity) as [TotalAmount]
	from uvw_DetailProductInOrder as D
	group by D.OrderId, D.OrderNumber, D.OrderDate
go
select *
from uvw_AllProductInOrder

---2.	Dùng view “uvw_DetailProductInOrder“ truy vấn những thông tin có OrderDate trong tháng 7 
select *
from uvw_DetailProductInOrder
where Month(OrderDate)=07

--3.	Dùng view “uvw_AllProductInOrder” truy vấn những hóa đơn Order có ít nhất 3 product trở lên
select * 
from uvw_AllProductInOrder
where (LEN(ProductList) - LEN(replace(ProductList,',',''))+1)>=3

---4.	Hai view trên đã readonly chưa ? Có những cách nào làm hai view trên thành readonly ?

create trigger dbo.uvw_DetailProductInOrder_Trigger_OnInsertOrUpdateOrDelete
on uvw_DetailProductInOrder
instead of insert,update,delete
as
begin
      raiserror ('You are not allow to update this view !',16,1)
end

create trigger dbo.uvw_uvw_AllProductInOrder_Trigger_OnInsertOrUpdateOrDelete
on uvw_AllProductInOrder
instead of insert,update,delete
as
begin
      raiserror ('You are not allow to update this view !',16,1)
end

---5.	Thống kê về thời gian thực thi khi gọi hai view trên. View nào chạy nhanh hơn ? 
SET STATISTICS IO ON 
SET STATISTICS TIME ON 
Go

SELECT * FROM uvw_DetailProductInOrder
GO
SELECT * FROM uvw_AllProductInOrder
GO

SET STATISTICS IO OFF 
SET STATISTICS TIME OFF 
GO

---1.	Viết hàm truyền vào một CustomerId và xuất ra tổng giá tiền (Total Amount)của các hóa đơn từ khách hàng đó. 
--Sau đó dùng hàm này xuất ra tổng giá tiền từ các hóa đơn của tất cả khách hàng
create function ufn_TotalAmounOfCustID(@CustomerID int =0)
returns int
as
begin
    declare @TotalAmount int

	select @TotalAmount=sum(TotalAmount)
	from [Order]
	where CustomerId=@CustomerID

	return @TotalAmount
end

select *,dbo.ufn_TotalAmounOfCustID(Id) as 'Total Amount of Customers'
from Customer

---2.	Viết hàm truyền vào hai số và xuất ra danh sách các sản phẩm có UnitPrice nằm trong khoảng hai số đó. 
create function ufn_ProductNameByUnitPrice(@Num1 decimal(5,2),@Num2 decimal(5,2))
returns table
as
return(

	select *
	from [Product]
	where UnitPrice >= @Num1 and UnitPrice<= @Num2
)

select *
from ufn_ProductNameByUnitPrice(15,25)


---3.	Viết hàm truyền vào một danh sách các tháng 'June;July;August;September và xuất ra thông tin của các hóa đơn có trong những tháng đó. 
--Viết cả hai hàm dưới dạng inline và multi statement sau đó cho biết thời gian thực thi của mỗi hàm, so sánh và đánh giá
-- inline function 
create function ufn_MonthFilterByOrders(@Month nvarchar(20))
returns table
as
return(
	select *
	from [Order]
	where charindex(ltrim(rtrim(lower(case month(OrderDate)
	                                       when 1 then 'January'
		                                   when 2 then 'February'
										   when 3 then 'March'
										   when 4 then 'April'
										   when 5 then 'May'
										   when 6 then 'June'
										   when 7 then 'July'
										   when 8 then 'August'
										   when 9 then 'Septemper'
										   when 10 then 'October'
										   when 11 then 'November'
										   else 'December'
										   end
										   ))),lower(@Month))>0
)
select * from ufn_MonthFilterByOrders('June;July;August;September')





-- multi-statement function
create function ufn_MonthFilterByOrders2(@Month nvarchar(max))
returns @ResultTable table (Id int,OrderDate Datetime, OrderNumber int, CustomerId int, TotalAmount float)
as
begin
    set @Month=lower(@Month);

	Insert into @ResultTable
	select Id ,OrderDate , OrderNumber , CustomerId , TotalAmount 
	from [Order]
	where charindex(ltrim(rtrim(lower(case month(OrderDate)
	                                       when 1 then 'January'
		                                   when 2 then 'February'
										   when 3 then 'March'
										   when 4 then 'April'
										   when 5 then 'May'
										   when 6 then 'June'
										   when 7 then 'July'
										   when 8 then 'August'
										   when 9 then 'Septemper'
										   when 10 then 'October'
										   when 11 then 'November'
										   else 'December'
										   end
										   ))),@Month)>0

	 return
end

select * from ufn_MonthFilterByOrders2('June;July;August;September')

SET STATISTICS TIME ON
select * from ufn_MonthFilterByOrders('June;July;August;September');
select * from ufn_MonthFilterByOrders2('June;July;August;September');
SET STATISTICS TIME OFF


---4.	Viết hàm kiểm tra mỗi hóa đơn không có quá 5 sản phẩm (kiểm tra trong bảng OrderItem). 
--Nếu insert quá 5 sản phẩm cho một hóa đơn thì báo lỗi và không cho insert. 
create function ufn_CheckProductExistence1(@ProductId INT)
returns bit
as
      begin
	     declare @Existence bit;
		 if((exists(select * from Product where Id=@ProductId)))
		     set @Existence=1;
		 else 
		     set @Existence=0;

		 return @Existence;
	   end
go

alter table OrderItem
add constraint CheckOrderItemExistence
    check (dbo.ufn_CheckProductExistence1(ProductId)=1);

Insert into Product values('New Product 1',100,10,'kgs',0)


--- 1.	Trigger:
--	Viết trigger khi xóa một OrderId thì xóa luôn các thông tin của Order đó trong bảng OrderItem. 
--Nếu có Foreign Key Constraint xảy ra không cho xóa thì hãy xóa Foreign Key Constraint đó đi rồi thực thi. 
create trigger [dbo].[Trigger_CustomerDeleted]
on [dbo].[OrderItem]
for delete
as
declare @DeletedOrderId int
select @DeletedOrderId=OrderId FROM deleted
print 'Cac hoa don cua OrderId='+ltrim(str(@DeletedOrderId)) + Space(1) +'da xoa';

alter table [OrderItem] drop constraint FK_ORDERITE_REFERENCE_ORDER
delete from [OrderItem] where Id=20

select * from [OrderItem] where OrderId=7


--	Viết trigger khi xóa hóa đơn của khách hàng Id = 1 thì báo lỗi không cho xóa sau đó ROLL BACK lại. 
--Lưu ý: Đưa trigger này lên làm Trigger đầu tiên thực thi xóa dữ liệu trên bảng Order
create trigger [dbo].[Trigger_CustomerIDDelete]
on [dbo].[Order]
for delete
as
   declare @DeletedOrderId int
   select @DeletedOrderId=CustomerId FROM deleted
   
   if(@DeletedOrderId=1)
   begin 
      raiserror  ('hóa đơn của khách hàng Id = 1 khong the xoa duoc',
	               16,
				   1);
	  rollback transaction
   end

exec sp_settriggerorder @triggername= 'Trigger_CustomerIDDelete',@order='first',@stmttype='delete'
delete from [Order] where CustomerId=1


--	Viết trigger không cho phép cập nhật Phone là NULL hay trong Phone có chữ cái ở bảng Supplier. Nếu có thì báo lỗi và ROLL BACK lại
create trigger [dbo].[Trigger_SupplierUpdate]
on [dbo].[Supplier]
for update
as
declare @UpdatePhone nvarchar(20)
if update(Phone)
select @updatePhone = Phone from inserted
	IF (@updatePhone IS NULL OR LOWER(@updatePhone) LIKE '%[abcdefghijklmnopqrstuvwxyz]%')
	begin
		raiserror ('Phone khong dược null hoặc chứa kí tự',16,1) 
		rollback transaction
end
Update Supplier set Phone=null where Id=2

--2.	Cursor:
--	Viết một function với input vào Country và xuất ra danh sách các Id và Company Name ở thành phố đó theo dạng sau 
--INPUT : ‘USA’
--OUTPUT : Companies in USA are : New Orleans Cajun Delights(ID:2) ; Grandma Kelly's Homestead(ID:3) ...
create function dbo.ufn_ListCompaniesByCountry2(@CountryDescr nvarchar(max))
returns nvarchar(max)
as
begin
    declare @CompanyList nvarchar(max)='Companies in ' + @CountryDescr + ' are : '  ;
	declare @Id int
	declare @CompanyName nvarchar(max)

	declare CompanyCursor cursor read_only
	for 
	select Id, CompanyName
	from Supplier
	where lower(Country) like '%' + LTRIM(RTRIM(LOWER(@CountryDescr)))+'%'

	open CompanyCursor

	fetch next from CompanyCursor into @Id,@CompanyName

	while @@FETCH_STATUS=0
	begin 
	     set @CompanyList=@CompanyList + @CompanyName + '('+ 'ID:'+ LTRIM(RTRIM(@Id))+')' + ';';
		 fetch next from CompanyCursor into @Id,@CompanyName
	END

	close CompanyCursor
	deallocate CompanyCursor

	return @CompanyList
end
select dbo.ufn_ListCompaniesByCountry2('USA')


---3.	Transaction:
--	Viết các dòng lệnh cập nhật Quantity của các sản phẩm trong bảng OrderItem mà có OrderID được đặt từ khách hàng USA. 
--Quantity được cập nhật bằng cách input vào một @DFactor sau đó Quantity được tính theo công thức Quantity = Quantity / @DFactor. 
--Ngoài ra còn xuất ra cho biết số lượng hóa đơn đã được cập nhật. (Sử dụng TRANSACTION để đảm bảo nếu có lỗi xảy ra thì ROLL BACK lại)
begin try
     begin transaction UpdateQuantityTrans
	    set nocount on;
		declare @NumOfUpdatedRecords int =0;
		declare @DFactor int;
		set @DFactor=1;

		update OI set Quantity = Quantity / @DFactor
		from OrderItem OI,[Order] O
		inner join Customer C on C.Id= O.CustomerId
		where OI.OrderId=O.Id and C.Country like '%USA%'

		set @NumOfUpdatedRecords=@@ROWCOUNT
		print 'Cap nhat thanh cong ' + LTRIM(RTRIM(@NumOfUpdatedRecords)) +' hoa don trong bang OrderItem';
      commit transaction UpdateQuantityTrans
end try
begin catch
     rollback tran UpdateQuantityTrans
	 print 'Cap nhat that bai. Xem chi tiet :';
	 print ERROR_MESSAGE();
end catch

---4.	Temp Table:
--	Viết TRANSACTION với Input là hai quốc gia. 
--Sau đó xuất thông tin là quốc gia nào có số sản phẩm cung cấp (thông qua SupplierId) nhiều hơn. 
-- Cho biết luôn số lượng số sản phẩm cung cấp của mỗi quốc gia. Sử dụng cả hai dạng bảng tạm (# và @) 
begin try
     begin transaction CompareTwoCountriesTrans
        set nocount on;
		declare @Country1 nvarchar(max);
		declare @Country2 nvarchar(max);

		set @Country1='Sweden';
		set @Country2='Finland';

		create table #ProductInfo1
		(	    
			Id int,
			Country nvarchar(max)
		)
		declare @ProductInfo2 table
		(	    
			Id int,
			Country nvarchar(max)
		)

		insert into #ProductInfo1
		select p.Id, s.Country
		from  Product as p inner join Supplier as s on s.Id = p.SupplierId
		where Country=@Country1

		insert into @ProductInfo2
		select p.Id, s.Country
		from  Product as p inner join Supplier as s on s.Id = p.SupplierId
		where Country=@Country1

		declare @NumProductSupplier1 int
		set @NumProductSupplier1=(select count(*) from #ProductInfo1);
		declare @NumProductSupplier2 int
		set @NumProductSupplier2=(select count(*) from @ProductInfo2);

		print 'Quoc gia ' +convert(NVARCHAR, @country1)+' co : '+ convert(NVARCHAR,@NumProductSupplier1) + ' so san pham cung cap'
		print 'Quoc gia ' +convert(NVARCHAR, @country2) +' co : '+convert(NVARCHAR,@NumProductSupplier2) + ' so san pham cung cap'

		print 
		case
		   when @NumProductSupplier1=@NumProductSupplier2
		      then 'So san pham cung cap cua quoc gia '+convert(NVARCHAR, @country1) + ' bang quoc gia ' +convert(NVARCHAR, @country2)
           when @NumProductSupplier1>@NumProductSupplier2
		      then 'So san pham cung cap cua quoc gia '+LTRIM(STR(@Country1)) + ' nhieu hon quoc gia ' +convert(NVARCHAR, @country2)
		   else 'So san pham cung cap cua quoc gia '+convert(NVARCHAR, @country2) + ' bang quoc gia ' +convert(NVARCHAR, @country1)
		end
		 
		drop table #ProductInfo1
commit transaction CompareTwoCountriesTrans
end try
begin catch
     rollback tran CompareTwoCountriesTrans
	 print 'Co loi xay ra. Xem chi tiet :';
	 print ERROR_MESSAGE();
end catch

