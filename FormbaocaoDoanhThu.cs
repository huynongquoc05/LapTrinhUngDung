using CrystalDecisions.CrystalReports.Engine;
using Microsoft.Data.SqlClient;
//* Nếu có lỗi với Microsoft.Data.SqlClient, tải package hoặc đổi thành using System.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WindowsFormsApp4
{
    public partial class FormbaocaoDoanhThu : Form
    {
        int year;int month;
        public FormbaocaoDoanhThu(int year,int month)
        {
            this.year = year;this.month = month;
            InitializeComponent();
        }
        public FormbaocaoDoanhThu()
        {
            InitializeComponent();
        }

        private void crystalReportViewer1_Load(object sender, EventArgs e)
        {

        }

        private void FormbaocaoDoanhThu_Load(object sender, EventArgs e)
        {
            string connection = Properties.Settings.Default.QuanLyBaiXe2ConnectionString;
            /*
             * Vào app.config để sửa lại connnectionString
             Khi kết nối bằng Tools - connect to database, chuỗi kết nối thường được tự động thêm vào app.config * */
            try
            {
                using (SqlConnection sqlConnection = new SqlConnection(connection))
                {
                    sqlConnection.Open();

                    // Tạo câu lệnh SQL dựa trên year và month
                    string query = "SELECT * FROM vw_BaoCaoDoanhThuVeLuotChiTiet";
                    if (year != 0 && month != 0)
                    {
                        query += $" WHERE RevenueYear = {year} AND RevenueMonth = {month}";
                    }
                    else if (year != 0)
                    {
                        query += $" WHERE RevenueYear = {year}";
                    }

                    using (SqlCommand sqlCommand = new SqlCommand(query, sqlConnection))
                    {
                        using (SqlDataAdapter sqlDataAdapter = new SqlDataAdapter(sqlCommand))
                        {
                            DataTable dataTable = new DataTable();
                            sqlDataAdapter.Fill(dataTable);
                            dataTable.TableName = "BaoCaoDoanhThu";

                            ReportDocument reportDocument = new ReportDocument();
                            string reportPath = Path.Combine(Application.StartupPath, "BaoCaoDoanhThu.rpt");
                            reportDocument.Load(reportPath);
                            reportDocument.SetDataSource(dataTable);
                            crystalReportViewer1.ReportSource = reportDocument;
                            crystalReportViewer1.Refresh();
                        }
                    }
                }
            }
            catch (SqlException ex)
            {
                MessageBox.Show("Lỗi kết nối SQL: " + ex.Message);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi: " + ex.Message);
            }
        }

    }
}
