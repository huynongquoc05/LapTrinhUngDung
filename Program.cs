using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WindowsFormsApp4
{
    internal static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Form1());
            /*
             * Vào app.config để sửa lại connnectionString
             * Nếu có lỗi với Microsoft.Data.SqlClient, tải package hoặc đổi thành using System.Data.SqlClient;
             * */
        }
    }
}
