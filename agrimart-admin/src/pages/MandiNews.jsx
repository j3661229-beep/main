import { useState, useEffect } from 'react';
import axios from 'axios';
import { toast } from 'react-hot-toast';

export default function MandiNews() {
  const [news, setNews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    title: '', content: '', source: '', imageUrl: '', state: '', district: '', crop: ''
  });

  const fetchNews = async () => {
    try {
      const { data } = await axios.get(`${import.meta.env.VITE_API_URL}/news`);
      setNews(data.data || []);
    } catch (error) {
      toast.error('Failed to load news');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNews();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${import.meta.env.VITE_API_URL}/news`, formData);
      toast.success('News published successfully');
      setFormData({ title: '', content: '', source: '', imageUrl: '', state: '', district: '', crop: '' });
      fetchNews();
    } catch (error) {
      toast.error('Failed to publish news');
    }
  };

  return (
    <div className="card" style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start' }}>
      <div style={{ flex: 1 }}>
        <h3>Publish News</h3>
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginTop: '1rem' }}>
          <input className="input" placeholder="Title" required value={formData.title} onChange={e => setFormData({ ...formData, title: e.target.value })} />
          <textarea className="input" placeholder="Content" required rows={4} value={formData.content} onChange={e => setFormData({ ...formData, content: e.target.value })} />
          <input className="input" placeholder="Source (Optional)" value={formData.source} onChange={e => setFormData({ ...formData, source: e.target.value })} />
          <input className="input" placeholder="Image URL (Optional)" value={formData.imageUrl} onChange={e => setFormData({ ...formData, imageUrl: e.target.value })} />
          <div style={{ display: 'flex', gap: '1rem' }}>
            <input className="input" placeholder="State" value={formData.state} onChange={e => setFormData({ ...formData, state: e.target.value })} />
            <input className="input" placeholder="District" value={formData.district} onChange={e => setFormData({ ...formData, district: e.target.value })} />
          </div>
          <button type="submit" className="btn btn-primary">Publish</button>
        </form>
      </div>

      <div style={{ flex: 1 }}>
        <h3>Recent News</h3>
        {loading ? <p>Loading...</p> : (
          <div style={{ marginTop: '1rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {news.map(n => (
              <div key={n.id} style={{ padding: '1rem', border: '1px solid var(--border-color)', borderRadius: 8 }}>
                <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{new Date(n.publishedAt).toLocaleDateString()}</div>
                <div style={{ fontWeight: 'bold', margin: '4px 0' }}>{n.title}</div>
                <div style={{ fontSize: 14 }}>{n.content}</div>
                <div style={{ fontSize: 12, marginTop: 8, color: 'var(--primary-color)' }}>
                  {n.district || 'National'} {n.district && n.state ? ', ' : ''} {n.state}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
