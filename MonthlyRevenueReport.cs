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
    public partial class MonthlyRevenueReport : Form
    {
        private int year = 0;
        private int month = 0;

        public MonthlyRevenueReport(int year,int month)
        {
            InitializeComponent();
            this.month = month;
            this.year = year;
        }
        
        public MonthlyRevenueReport()
        {
            InitializeComponent();
        }

        private void MonthlyRevenueReport_Load(object sender, EventArgs e)
        {
            string connection = Properties.Settings.Default.QuanLyBaiXe2ConnectionString;
            /*
             * Vào app.config để sửa lại connnectionString
             Khi kết nối bằng Tools - connect to database, chuỗi kết nối thường được tự động thêm vào app.config 
            * */

            try
            {
                using (SqlConnection sqlConnection = new SqlConnection(connection))
                {
                    sqlConnection.Open();

                    string query = "SELECT * FROM vw_BaoCaoDangKyThang";

                    // Nếu có truyền năm hoặc tháng thì lọc theo ngày bắt đầu
                    if (year != 0 && month != 0)
                    {
                        query += " WHERE MONTH(StartDate) = @month AND YEAR(StartDate) = @year";
                    }
                    else if (year != 0 && month == 0)
                    {
                        query += " WHERE YEAR(StartDate) = @year";
                    }
                    else if (year == 0 && month != 0)
                    {
                        // Có thể cảnh báo trước ở nơi gọi như bạn đã làm
                        query += " WHERE MONTH(StartDate) = @month";
                    }

                    using (SqlCommand sqlCommand = new SqlCommand(query, sqlConnection))
                    {
                        if (year != 0) sqlCommand.Parameters.AddWithValue("@year", year);
                        if (month != 0) sqlCommand.Parameters.AddWithValue("@month", month);

                        using (SqlDataAdapter sqlDataAdapter = new SqlDataAdapter(sqlCommand))
                        {
                            DataTable dataTable = new DataTable();
                            sqlDataAdapter.Fill(dataTable);
                            dataTable.TableName = "BaoCaoDoanhThuVeThang";

                            ReportDocument reportDocument = new ReportDocument();
                            string path = Path.Combine(Application.StartupPath, "CrystalReport2.rpt");
                            reportDocument.Load(path);
                            reportDocument.SetDataSource(dataTable);
                            crystalReportViewer1.ReportSource = reportDocument;
                            crystalReportViewer1.Refresh();
                        }
                    }
                }
            }
            catch (SqlException ex)
            {
                MessageBox.Show(ex.ToString());
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString());
            }
        }
    }
}

