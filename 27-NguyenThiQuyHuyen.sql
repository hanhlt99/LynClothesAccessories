Use QUANLYNHANVIEN
select * from THAMGIA
select * from DUAN
select * from NHANVIEN
select * from PHONGBAN
--27
--ham
-- a.Trả về số lượng ngày công của nhân viên nếu biết mã nhân viên và mã dự án. 
create function fslngaycong (@manv nvarchar(10),@mada nvarchar(10))
returns numeric(18,0)
as
begin
	declare @slnc numeric (18,0)
	set @slnc =(select SoLuongNgayCong from THAMGIA
				where MaNV=@manv and MaDA=@mada)
	return @slnc
end
select dbo.fslngaycong('N0003','DA001')
--b.Kiểm tra mã dự án đã tồn tại trong trong bảng DUAN hay chưa?
--Input: mã dự án. Output: 1 (nếu tồn tại), 0(nếu không tồn tại)
create function Fktmda (@mada nvarchar(10))
returns int
as
begin
	declare @trave int
	if exists (select * from DUAN
						where MaDA=@mada)
		set @trave ='1'
	else 
		set @trave= '0'
	return @trave	
end
select dbo.Fktmda('DA001')
--c Kiểm tra mã NHANVIEN đã tồn tại trong bảng NHANVIEN hay chưa?
--Input: mã nhân viên. Output: 1 (nếu tồn tại), 0(nếu không tồn tại)
create function Fktmnv (@manv nvarchar(10))
returns int
as
begin
	declare @trave int
	if exists (select * from NHANVIEN
						where MaNV=@manv)
		set @trave ='1'
	else 
		set @trave= '0'
	return @trave	
end
select dbo.Fktmnv('N0235')
--2.Tạo thủ tục thêm mới dữ liệu nhân viên tham gia dự án như mô tả dưới đây:
--Input: Mã nhân viên, mã dự án, số lượng ngày công
--Output: 1(nếu thêm mới thành công), 0(nếu thêm mới thất bại)
--Process:
--B1: Kiểm tra mã nhân viên đã tồn tại chưa? Nếu chưa tồn tại, đưa ra thông báo lỗi và kết thúc
--B2: Kiểm tra mã dự án đã tồn tại chưa? Nếu chưa tồn tại, đưa ra thông báo lỗi và kết thúc
--B3: Kiểm tra số lượng ngày công. Nếu lớn hơn 0 thì thêm mới dữ liệu vào bảng THAMGIA, ngược lại thông báo lỗi và kết thúc.
alter proc spthemmoi @mada nvarchar(10),@manv nvarchar(10),@slnc numeric(18,0), @trave int out
as 
begin
	if not exists(select * from NHANVIEN where MaNV=@manv)
		begin
		print 'Ma nv chua ton tai'  
		return
		end
	else if not exists (select * from DUAN where MaDA =@mada)
			begin
			print 'ma du an chua ton tai'
			return
			end
	else if @slnc <0 
			begin
				print'SL ngay cong nho hon 0'
				return
			end
		else 
		insert into THAMGIA values(@mada,@manv,@slnc)
		begin
	if @@ROWCOUNT>0
		set @trave ='1'
	else
		set @trave='0'
	end
end
declare @a int
exec spthemmoi 'DA011','N0300','17',@a out
print @a
select * from THAMGIA
delete from THAMGIA
where MaDA='DA001' and MaNV ='N0001' and SoLuongNgayCong='17'
---cách khác:
create proc spinsert @mada nvarchar(10),@manv nvarchar(10),@slnc numeric(18,0), @trave int out
as 
begin
	declare @tontai int
	set @tontai= dbo.Fktmnv(@manv)
	if @tontai=0
		begin 
			print N'Mã nhân viên chưa tồn tại'
			return
		end
	else if @tontai=1
	begin
		set @tontai= dbo.Fktmda(@mada)
		if @tontai =0
		begin
			print N'Mã dự án chưa tồn tại'
			return
		end
	end
	else if @slnc < 0
		begin
			print N'Số lượng ngày công không đúng'
			return
		end
	else 
		insert into THAMGIA values(@mada, @manv,@slnc)
		if @@ROWCOUNT >0
		set @trave = 1
		else 
		set @trave=0
end
declare @a int
exec spthemmoi 'DA011','N0211','-2',@a out
print @a



--3. Tạo trigger thực hiện yêu cầu sau:
--Khi thêm mới dữ liệu cho bảng DUAN, NgayBD có sau NgayKT hay không,
--nếu có thì thông báo lỗi và undo toàn bộ thao tác.
select *from DUAN
alter trigger themmoidl 
on DUAN for insert
as
begin
	declare @ngaybd date, @ngaykt date
	set @ngaybd =( select NgayBD from inserted)
	set @ngaykt =( select NgayKT from inserted)
	if (year(@ngaybd) > year(@ngaykt))
	begin
		print N'Năm k đúng'
		rollback 
	end
	else if (MONTH(@ngaybd) >MONTH(@ngaykt) and (YEAR(@ngaybd)= YEAR(@ngaykt)))
	begin
		Print N'Tháng K hợp lệ'
		rollback
	end
	else if (day(@ngaybd) > DAY(@ngaykt) and (MONTH(@ngaybd) = MONTH(@ngaykt) and YEAR(@ngaybd) = YEAR(@ngaykt)))
	begin
		Print N'ngày k hợp lệ'
		rollback
	end
	else 
		commit
end
--test 
insert into DUAN (MaDA,TenDA,NgayBD,NgayKT)
values ('DA017',N'dự án test thử','2014-01-12','2014-01-18')
select * from DUAN 
where MaDA ='DA017'
delete  from DUAN
where MaDA = 'DA017'
