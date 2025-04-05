using CrystalDecisions.CrystalReports.Engine;
using Microsoft.Data.SqlClient;
//Nếu có lỗi với Microsoft.Data.SqlClient, tải package hoặc đổi thành using System.Data.SqlClient;
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
    public partial class TongDoanhThu : Form
    {
        public TongDoanhThu()
        {
            InitializeComponent();
        }

        private void TongDoanhThu_Load(object sender, EventArgs e)
        {
            string connection = Properties.Settings.Default.QuanLyBaiXe2ConnectionString;

            /*
             * Vào app.config để sửa lại connnectionString
             * Khi kết nối bằng Tools - connect to database, chuỗi kết nối thường được tự động thêm vào app.config 
             * */

            try
            {
                using (SqlConnection sqlConnection = new SqlConnection(connection))
                {
                    using (SqlCommand sqlCommand = new SqlCommand("EXEC sp_CalculateTotalRevenue;", sqlConnection))
                    {
                        using (SqlDataAdapter sqlDataAdapter = new SqlDataAdapter(sqlCommand))
                        {
                            DataTable dataTable = new DataTable();
                            sqlDataAdapter.Fill(dataTable);
                            dataTable.TableName = "BaoCaoTongDoanhThu";
                            //CrystalReport2 crystalReport2 = new CrystalReport2();
                            //crystalReport2.SetDataSource(dataTable);
                            //crystalReportViewer1.ReportSource = crystalReport2;
                            //crystalReportViewer1.Refresh();
                            ReportDocument reportDocument = new ReportDocument();
                            string reportPath = Path.Combine(Application.StartupPath, "CrystalReport3.rpt");
                            reportDocument.Load(reportPath);

                            reportDocument.SetDataSource(dataTable);
                            crystalReportViewer1.ReportSource = reportDocument;
                            crystalReportViewer1.Refresh();

                        }
                    }
                }
            }
            catch (SqlException s)
            {
                MessageBox.Show(e.ToString());
            }
            catch (Exception ee)
            {
                MessageBox.Show(ee.ToString());
            }
        }
    }
}
