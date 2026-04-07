const nodemailer = require('nodemailer');

const sendEmail = async (options) => {
  if (!process.env.EMAIL_HOST || !process.env.EMAIL_PORT || !process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn('Email config missing; skipping email send.');
    return;
  }

  const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });

  const mailOptions = {
    from: `Clothing Store <${process.env.EMAIL_USER}>`,
    to: options.email,
    subject: options.subject,
    html: options.message || options.html || '<p>No message content provided.</p>'
  };

  await transporter.sendMail(mailOptions);
};

module.exports = sendEmail;