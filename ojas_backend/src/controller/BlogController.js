const Blog = require('../model/Blog');
const imagekit = require("../config/imagekit.js");

exports.createBlog = async (req, res) => {
  try {
    let imageUrl = "";
    if (req.file) {
      try {
        const uploadResponse = await imagekit.files.upload({
          file: req.file.buffer.toString('base64'),
          fileName: `blog_${Date.now()}.png`,
          folder: "/blogs",
        });
        imageUrl = uploadResponse.url;
      } catch (err) {
        console.error("ImageKit Upload Error:", err.message);
        return res.status(500).json({ message: "Image upload failed: " + err.message });
      }
    } else if (req.body.imageUrl) {
      imageUrl = req.body.imageUrl;
    }

    const blogData = { ...req.body, image: imageUrl };
    const blog = new Blog(blogData);
    await blog.save();

    // Emit socket event
    const io = req.app.get("io");
    if (io) {
      io.emit("admin_data_updated", { type: "blog", action: "create", data: blog });
    }

    res.status(201).json({ success: true, data: blog, message: "Blog created successfully" });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.getAllBlogs = async (req, res) => {
  try {
    const blogs = await Blog.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: blogs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getBlogById = async (req, res) => {
  try {
    const blog = await Blog.findById(req.params.id);
    if (!blog) {
      return res.status(404).json({ success: false, message: 'Blog not found' });
    }
    // Increment views
    blog.views += 1;
    await blog.save();

    // Emit socket event
    const io = req.app.get("io");
    if (io) {
      io.emit("blog", { type: "blog", action: "update", data: blog });
    }

    res.status(200).json({ success: true, data: blog });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateBlog = async (req, res) => {
  try {
    const { id } = req.params;
    let updateData = { ...req.body };

    if (req.file) {
      try {
        const uploadResponse = await imagekit.files.upload({
          file: req.file.buffer.toString('base64'),
          fileName: `blog_${Date.now()}.png`,
          folder: "/blogs",
        });
        updateData.image = uploadResponse.url;
      } catch (err) {
        console.error("ImageKit Upload Error:", err.message);
        return res.status(500).json({ message: "Image upload failed: " + err.message });
      }
    }

    const blog = await Blog.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
    if (!blog) {
      return res.status(404).json({ success: false, message: 'Blog not found' });
    }

    // Emit socket event
    const io = req.app.get("io");
    if (io) {
      io.emit("admin_data_updated", { type: "blog", action: "update", data: blog });
    }

    res.status(200).json({ success: true, data: blog, message: "Blog updated successfully" });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteBlog = async (req, res) => {
  try {
    const { id } = req.params;
    const blog = await Blog.findByIdAndDelete(id);
    if (!blog) {
      return res.status(404).json({ success: false, message: 'Blog not found' });
    }

    // Emit socket event
    const io = req.app.get("io");
    if (io) {
      io.emit("admin_data_updated", { type: "blog", action: "delete", id });
    }

    res.status(200).json({ success: true, message: 'Blog deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.incrementView = async (req, res) => {
  try {
    const blog = await Blog.findByIdAndUpdate(
      req.params.id,
      { $inc: { views: 1 } },
      { new: true }
    );
    if (!blog) {
      return res.status(404).json({ success: false, message: 'Blog not found' });
    }
    
    // Emit socket event so UI updates everywhere
    const io = req.app.get("io");
    if (io) {
      io.emit("blog", { type: "blog", action: "update", data: blog });
    }

    res.status(200).json({ success: true, data: blog });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
