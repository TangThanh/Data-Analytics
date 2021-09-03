use Northwind;
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

