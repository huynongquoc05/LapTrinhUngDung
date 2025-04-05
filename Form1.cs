using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Data.SqlClient;
namespace WindowsFormsApp4
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            //string connection = "Data Source=DESKTOP-AMN3OI8;Initial Catalog=QuanLyBaiXe2;Persist Security Info=True;User ID=sa;Password=051120;Trust Server Certificate=True";
            //using (SqlConnection sqlConnection =new SqlConnection(connection))
            //{
            //    using(SqlCommand sqlCommand =new SqlCommand("SELECT * FROM vw_BaoCaoDangKyThang;", sqlConnection))
            //    {
            //        using (SqlDataAdapter sqlDataAdapter = new SqlDataAdapter(sqlCommand))
            //        {
            //            DataTable dataTable = new DataTable();
            //            sqlDataAdapter.Fill(dataTable);
            //            dataTable.TableName = "BaoCaoDoanhThuVethang";
            //            dataTable.WriteXml("C:\\Users\\VICTUS\\source\\repos\\WindowsFormsApp4\\BaoCaoDoanhThuVethang.xml");
            //       }
            //    }
            //}
            comboBox1.Items.Add("All");
            comboBox2.Items.Add("All");
            for (int i = 2019; i <= 2025; i++)
            {
                comboBox1.Items.Add(i);
            }
            for (int i = 1; i < 13; i++)
            {
                comboBox2.Items.Add(i);
            }
            // Gán mặc định hiển thị "All" khi form load
            comboBox1.SelectedItem = "All";
            comboBox2.SelectedItem = "All";
        }

        private void button1_Click(object sender, EventArgs e)
        {
            // Lấy giá trị được chọn từ ComboBox
            string selectedYear = comboBox1.SelectedItem.ToString();
            string selectedMonth = comboBox2.SelectedItem.ToString();

            // Trường hợp cả năm và tháng đều là "All"
            if (selectedYear == "All" && selectedMonth == "All")
            {
                FormbaocaoDoanhThu form = new FormbaocaoDoanhThu();
                this.Hide();
                form.Show();
                form.FormClosed += ShowCurrent;
            }
            // Trường hợp năm cụ thể, tháng là "All"
            else if (selectedYear != "All" && selectedMonth == "All")
            {
                int year = Convert.ToInt32(selectedYear);
                FormbaocaoDoanhThu form = new FormbaocaoDoanhThu(year, 0); // month = 0 => lọc theo năm
                this.Hide();
                form.Show();
                form.FormClosed += ShowCurrent;
            }
            // Trường hợp cả năm và tháng đều cụ thể
            else if (selectedYear != "All" && selectedMonth != "All")
            {
                int year = Convert.ToInt32(selectedYear);
                int month = Convert.ToInt32(selectedMonth);
                FormbaocaoDoanhThu form = new FormbaocaoDoanhThu(year, month);
                this.Hide();
                form.Show();
                form.FormClosed += ShowCurrent;
            }
            // Trường hợp chọn tháng cụ thể nhưng không chọn năm
            else
            {
                MessageBox.Show("Vui lòng chọn năm nếu muốn lọc theo tháng!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }


        public void ShowCurrent(object sender, FormClosedEventArgs e)
        {
            this.Show();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            string selectedYear = comboBox1.SelectedItem.ToString();
            string selectedMonth = comboBox2.SelectedItem.ToString();

            // Cả năm và tháng đều là "All"
            if (selectedYear == "All" && selectedMonth == "All")
            {
                MonthlyRevenueReport form = new MonthlyRevenueReport();
                this.Hide();
                form.Show();
                form.FormClosed += ShowCurrent;
            }
            // Năm cụ thể, tháng là "All"
            else if (selectedYear != "All" && selectedMonth == "All")
            {
                int year = Convert.ToInt32(selectedYear);
                MonthlyRevenueReport form = new MonthlyRevenueReport(year, 0);
                this.Hide();
                form.Show();
                form.FormClosed += ShowCurrent;
            }
            // Năm và tháng đều cụ thể
            else if (selectedYear != "All" && selectedMonth != "All")
            {
                int year = Convert.ToInt32(selectedYear);
                int month = Convert.ToInt32(selectedMonth);
                MonthlyRevenueReport form = new MonthlyRevenueReport(year, month);
                this.Hide();
                form.Show();
                form.FormClosed += ShowCurrent;
            }
            // Chọn tháng nhưng không chọn năm
            else
            {
                MessageBox.Show("Vui lòng chọn năm nếu muốn lọc theo tháng!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            TongDoanhThu tongDoanhThu = new TongDoanhThu();
            this.Hide();
            tongDoanhThu.Show();
            tongDoanhThu.FormClosed += ShowCurrent;
        }
    }
}
