import { useState, useEffect } from 'react';
import { getNews, createNews } from '../lib/api';
import { toast } from 'react-hot-toast';

export default function MandiNews() {
  const [news, setNews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    title: '', content: '', source: '', imageUrl: '', state: '', district: '', crop: ''
  });

  const fetchNews = async () => {
    setLoading(true);
    try {
      const res = await getNews({ limit: 20 });
      setNews(res.data || []);
    } catch {
      toast.error('Failed to load news');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchNews(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title || !formData.content) {
      toast.error('Title and content are required');
      return;
    }
    setSubmitting(true);
    try {
      await createNews(formData);
      toast.success('News published successfully');
      setFormData({ title: '', content: '', source: '', imageUrl: '', state: '', district: '', crop: '' });
      fetchNews();
    } catch {
      toast.error('Failed to publish news');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="animate-fade">
      <div className="grid-2" style={{ alignItems: 'flex-start', gap: 24 }}>
        {/* Publish Form */}
        <div className="card card-body">
          <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 20 }}>📰 Publish News</h3>
          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div className="input-group">
              <label className="input-label">Title *</label>
              <input className="input" placeholder="News headline" required value={formData.title}
                onChange={e => setFormData({ ...formData, title: e.target.value })} />
            </div>
            <div className="input-group">
              <label className="input-label">Content *</label>
              <textarea className="input" placeholder="Full news content" required rows={4} value={formData.content}
                onChange={e => setFormData({ ...formData, content: e.target.value })} />
            </div>
            <div className="input-group">
              <label className="input-label">Source</label>
              <input className="input" placeholder="e.g. Krishi Jagran, PTI" value={formData.source}
                onChange={e => setFormData({ ...formData, source: e.target.value })} />
            </div>
            <div className="input-group">
              <label className="input-label">Image URL</label>
              <input className="input" placeholder="https://..." value={formData.imageUrl}
                onChange={e => setFormData({ ...formData, imageUrl: e.target.value })} />
            </div>
            <div className="input-group">
              <label className="input-label">Crop (optional)</label>
              <input className="input" placeholder="e.g. Onion, Wheat" value={formData.crop}
                onChange={e => setFormData({ ...formData, crop: e.target.value })} />
            </div>
            <div style={{ display: 'flex', gap: 12 }}>
              <div className="input-group" style={{ flex: 1 }}>
                <label className="input-label">State</label>
                <input className="input" placeholder="Maharashtra" value={formData.state}
                  onChange={e => setFormData({ ...formData, state: e.target.value })} />
              </div>
              <div className="input-group" style={{ flex: 1 }}>
                <label className="input-label">District</label>
                <input className="input" placeholder="Nashik" value={formData.district}
                  onChange={e => setFormData({ ...formData, district: e.target.value })} />
              </div>
            </div>
            <button type="submit" className="btn btn-primary" style={{ justifyContent: 'center' }} disabled={submitting}>
              {submitting ? <><span className="btn-spinner" /> Publishing…</> : '📢 Publish News'}
            </button>
          </form>
        </div>

        {/* News Feed */}
        <div>
          <div className="flex-between mb-16">
            <h3 style={{ fontSize: 15, fontWeight: 700 }}>📋 Recent News ({news.length})</h3>
            <button className="btn btn-sm btn-outline" onClick={fetchNews}>↻ Refresh</button>
          </div>
          {loading ? (
            <div className="page-loader"><div className="loading-spinner" /></div>
          ) : news.length === 0 ? (
            <div className="card"><div className="empty-state">
              <div className="icon">📰</div>
              <h3>No news yet</h3>
              <p>Publish your first news article</p>
            </div></div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {news.map(n => (
                <div key={n.id} className="card card-body" style={{ padding: 16 }}>
                  {n.imageUrl && (
                    <img src={n.imageUrl} alt={n.title}
                      style={{ width: '100%', height: 140, objectFit: 'cover', borderRadius: 8, marginBottom: 10 }}
                      onError={e => e.target.style.display = 'none'} />
                  )}
                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 6 }}>
                    {n.crop && <span className="badge badge-success">{n.crop}</span>}
                    {n.district && <span className="badge badge-info">{n.district}</span>}
                    {n.state && <span className="badge badge-gray">{n.state}</span>}
                  </div>
                  <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 4 }}>{n.title}</div>
                  <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
                    {n.content.slice(0, 120)}{n.content.length > 120 ? '…' : ''}
                  </div>
                  <div className="flex-between" style={{ marginTop: 10 }}>
                    <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>
                      {n.source && <>{n.source} · </>}
                      {new Date(n.publishedAt || n.createdAt).toLocaleDateString('en-IN')}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
